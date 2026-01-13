from fastapi import FastAPI, UploadFile, File, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import io
import uvicorn
import os

from covenant_engine import CovenantEngine
from data_processor import DataProcessor
from database import engine, get_db
import models
import schemas
from auth import get_password_hash, verify_password, create_access_token, get_current_user
import pdfplumber

# Create tables (Dev only - use Alembic for Prod)
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="CreditSentinel API")

# Enable CORS for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

engine_ai = CovenantEngine()
processor = DataProcessor()


# Helper to log events (persisted to DB)
def log_event(db: Session, event_type: str, details: str, user_id: int = None):
    log = models.AuditLog(event_type=event_type, details=details, user_id=user_id)
    db.add(log)
    db.commit()

# --- Authentication Endpoints ---
@app.post("/token")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/register", response_model=schemas.User)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_pwd = get_password_hash(user.password)
    new_user = models.User(email=user.email, hashed_password=hashed_pwd)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    try:
        db.execute("SELECT 1")
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "database": str(e)}

# --- Protected Endpoints ---
@app.get("/logs")
async def get_logs(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    logs = db.query(models.AuditLog).order_by(models.AuditLog.timestamp.desc()).limit(50).all()
    return logs

@app.post("/simulate")
async def simulate(data: dict, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # ... (Keep simulation logic but use current_user for logs)
    ebitda_factor = 1.0 + data.get("ebitda_change", 0.0)
    debt_factor = 1.0 + data.get("debt_change", 0.0)
    
    simulation_results = []
    base_ratios = {"Debt-to-EBITDA": 3.2, "Interest Coverage": 2.5, "Current Ratio": 1.2}
    
    # Normally fetch active covenants from DB
    covenants = db.query(models.Covenant).all() or engine_ai.extract_covenants("")
    
    for cov in covenants:
        # Handle dict or ORM object
        name = cov.name if isinstance(cov, models.Covenant) else cov["name"]
        val = base_ratios.get(name, 1.0)
        
        if name == "Debt-to-EBITDA":
            sim_val = round(val * (debt_factor / ebitda_factor), 2)
        elif name == "Interest Coverage":
            sim_val = round(val * ebitda_factor, 2)
        else:
            sim_val = val
            
        # Needs adapter for evaluating ORM objects vs dicts
        cov_dict = cov.__dict__ if isinstance(cov, models.Covenant) else cov
        eval_res = engine_ai.evaluate(cov_dict, sim_val)
        
        simulation_results.append({
            "name": name,
            **eval_res,
            "explanation": engine_ai.generate_explanation(cov_dict, eval_res)
        })
    
    log_event(db, "Simulation", f"What-if run (EBITDA: {ebitda_factor}x, Debt: {debt_factor}x)", current_user.id)
    return simulation_results

@app.post("/upload-agreement")
async def upload_agreement(file: UploadFile = File(...), db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    content = await file.read()
    
    # Robust text extraction
    text = ""
    if file.content_type == "application/pdf" or file.filename.lower().endswith(".pdf"):
        try:
            with pdfplumber.open(io.BytesIO(content)) as pdf:
                for page in pdf.pages:
                    text += page.extract_text() or ""
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"PDF Processing Error: {str(e)}")
    else:
        text = content.decode("utf-8", errors="ignore") 
    
    covenants = engine_ai.extract_covenants(text)
    
    # Persist covenants
    for cov in covenants:
        db_cov = models.Covenant(
            name=cov["name"], 
            threshold=cov["threshold"], 
            operator=cov["operator"],
            category=cov["category"],
            status="Pending"
        )
        db.add(db_cov)
    db.commit()
    
    log_event(db, "Upload", f"Loan agreement uploaded: {file.filename}", current_user.id)
    return {"filename": file.filename, "status": "processed", "covenants": covenants}

@app.post("/upload-financials")
async def upload_financials(file: UploadFile = File(...), db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    content = await file.read()
    df = processor.normalize_financials(content, file.filename)
    ratios = processor.calculate_ratios(df)
    
    report = []
    # Fetch from DB
    active_covenants = db.query(models.Covenant).all()
    
    for cov in active_covenants:
        val = ratios.get(cov.name)
        if val is not None:
            cov_dict = cov.__dict__
            evaluation = engine_ai.evaluate(cov_dict, val)
            
            # Update DB status
            cov.current_value = val
            cov.status = evaluation["status"]
            
            report.append({
                "name": cov.name,
                **evaluation,
                "explanation": engine_ai.generate_explanation(cov_dict, evaluation)
            })
    
    db.commit()
    log_event(db, "Analysis", f"Financials analyzed: {file.filename}", current_user.id)
    return {
        "filename": file.filename,
        "summary": report,
        "ratios": ratios
    }


# Serve Flutter Web build if it exists (at the end to avoid shadowing)
if os.path.exists("../frontend/build/web"):
    app.mount("/", StaticFiles(directory="../frontend/build/web", html=True), name="static")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
