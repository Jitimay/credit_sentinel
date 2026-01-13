from fastapi import FastAPI, UploadFile, File, HTTPException, Depends, status, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import io
import uvicorn
import os
import logging
import magic
from contextlib import asynccontextmanager

from covenant_engine import CovenantEngine
from data_processor import DataProcessor
from database import engine, get_db, init_db
import models
import schemas
from auth import get_password_hash, verify_password, create_access_token, get_current_user
import pdfplumber

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Rate limiting
limiter = Limiter(key_func=get_remote_address)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting CreditSentinel API...")
    init_db()
    yield
    # Shutdown
    logger.info("Shutting down CreditSentinel API...")

app = FastAPI(
    title="CreditSentinel API",
    version="1.0.0",
    description="AI-Powered Loan Covenant Monitoring System",
    lifespan=lifespan
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS configuration for production
allowed_origins = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8080").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Initialize services
engine_ai = CovenantEngine(use_llm=os.getenv("GEMINI_API_KEY") is not None)
processor = DataProcessor()

# File validation
ALLOWED_MIME_TYPES = {
    'application/pdf': ['.pdf'],
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['.xlsx'],
    'application/vnd.ms-excel': ['.xls'],
    'text/csv': ['.csv']
}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB

def validate_file(file: UploadFile) -> None:
    """Validate uploaded file type and size"""
    if file.size > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail="File too large")
    
    # Read first chunk to detect MIME type
    file.file.seek(0)
    chunk = file.file.read(1024)
    file.file.seek(0)
    
    mime_type = magic.from_buffer(chunk, mime=True)
    if mime_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(status_code=400, detail=f"Unsupported file type: {mime_type}")

def log_event(db: Session, event_type: str, details: str, user_id: int = None, loan_id: int = None):
    """Enhanced logging with loan context"""
    try:
        log = models.AuditLog(
            event_type=event_type, 
            details=details, 
            user_id=user_id,
            loan_id=loan_id
        )
        db.add(log)
        db.commit()
        logger.info(f"Event logged: {event_type} - {details}")
    except Exception as e:
        logger.error(f"Failed to log event: {e}")

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "error_code": "INTERNAL_ERROR"}
    )

# --- Authentication Endpoints ---
@app.post("/token")
@limiter.limit("5/minute")
async def login(request: Request, form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    try:
        user = db.query(models.User).filter(models.User.email == form_data.username).first()
        if not user or not verify_password(form_data.password, user.hashed_password):
            log_event(db, "LOGIN_FAILED", f"Failed login attempt for {form_data.username}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        access_token = create_access_token(data={"sub": user.email})
        log_event(db, "LOGIN_SUCCESS", f"User {user.email} logged in", user.id)
        return {"access_token": access_token, "token_type": "bearer"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Login error: {e}")
        raise HTTPException(status_code=500, detail="Login failed")

@app.post("/register", response_model=schemas.User)
@limiter.limit("3/minute")
async def register(request: Request, user: schemas.UserCreate, db: Session = Depends(get_db)):
    try:
        db_user = db.query(models.User).filter(models.User.email == user.email).first()
        if db_user:
            raise HTTPException(status_code=400, detail="Email already registered")
        
        hashed_pwd = get_password_hash(user.password)
        new_user = models.User(email=user.email, hashed_password=hashed_pwd)
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        log_event(db, "USER_REGISTERED", f"New user registered: {user.email}", new_user.id)
        return new_user
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Registration error: {e}")
        raise HTTPException(status_code=500, detail="Registration failed")

@app.get("/health")
async def health_check(db: Session = Depends(get_db)):
    try:
        db.execute("SELECT 1")
        return {"status": "healthy", "database": "connected", "version": "1.0.0"}
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {"status": "unhealthy", "database": str(e)}

# --- Loan Management ---
@app.post("/loans", response_model=schemas.Loan)
async def create_loan(
    loan: schemas.LoanCreate, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_user)
):
    try:
        db_loan = models.Loan(**loan.dict(), owner_id=current_user.id)
        db.add(db_loan)
        db.commit()
        db.refresh(db_loan)
        
        log_event(db, "LOAN_CREATED", f"Loan created for {loan.borrower_name}", current_user.id, db_loan.id)
        return db_loan
    except Exception as e:
        logger.error(f"Loan creation error: {e}")
        raise HTTPException(status_code=500, detail="Failed to create loan")

@app.get("/loans", response_model=list[schemas.Loan])
async def get_loans(
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_user)
):
    return db.query(models.Loan).filter(models.Loan.owner_id == current_user.id).all()

# --- Protected Endpoints ---
@app.get("/logs")
@limiter.limit("10/minute")
async def get_logs(
    request: Request,
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_user)
):
    logs = db.query(models.AuditLog).filter(
        models.AuditLog.user_id == current_user.id
    ).order_by(models.AuditLog.timestamp.desc()).limit(50).all()
    return logs

@app.post("/upload-agreement", response_model=schemas.FileUploadResponse)
@limiter.limit("5/minute")
async def upload_agreement(
    request: Request,
    loan_id: int,
    file: UploadFile = File(...), 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_user)
):
    try:
        # Validate loan ownership
        loan = db.query(models.Loan).filter(
            models.Loan.id == loan_id, 
            models.Loan.owner_id == current_user.id
        ).first()
        if not loan:
            raise HTTPException(status_code=404, detail="Loan not found")
        
        validate_file(file)
        content = await file.read()
        
        # Extract text
        text = ""
        if file.content_type == "application/pdf":
            with pdfplumber.open(io.BytesIO(content)) as pdf:
                for page in pdf.pages:
                    text += page.extract_text() or ""
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
                status="Pending",
                loan_id=loan_id
            )
            db.add(db_cov)
        db.commit()
        
        log_event(db, "AGREEMENT_UPLOADED", f"Agreement uploaded: {file.filename}", current_user.id, loan_id)
        return schemas.FileUploadResponse(
            filename=file.filename, 
            status="processed", 
            message=f"Extracted {len(covenants)} covenants"
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Agreement upload error: {e}")
        raise HTTPException(status_code=500, detail="Failed to process agreement")

@app.post("/upload-financials", response_model=schemas.FileUploadResponse)
@limiter.limit("10/minute")
async def upload_financials(
    request: Request,
    loan_id: int,
    file: UploadFile = File(...), 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_user)
):
    try:
        # Validate loan ownership
        loan = db.query(models.Loan).filter(
            models.Loan.id == loan_id, 
            models.Loan.owner_id == current_user.id
        ).first()
        if not loan:
            raise HTTPException(status_code=404, detail="Loan not found")
        
        validate_file(file)
        content = await file.read()
        df = processor.normalize_financials(content, file.filename)
        ratios = processor.calculate_ratios(df)
        
        # Update covenants
        active_covenants = db.query(models.Covenant).filter(
            models.Covenant.loan_id == loan_id
        ).all()
        
        updated_count = 0
        for cov in active_covenants:
            val = ratios.get(cov.name)
            if val is not None:
                evaluation = engine_ai.evaluate(cov.__dict__, val)
                cov.current_value = val
                cov.status = evaluation["status"]
                updated_count += 1
        
        db.commit()
        log_event(db, "FINANCIALS_ANALYZED", f"Updated {updated_count} covenants", current_user.id, loan_id)
        
        return schemas.FileUploadResponse(
            filename=file.filename,
            status="processed",
            message=f"Updated {updated_count} covenants"
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Financials upload error: {e}")
        raise HTTPException(status_code=500, detail="Failed to process financials")

# Serve static files last
if os.path.exists("../frontend/build/web"):
    app.mount("/", StaticFiles(directory="../frontend/build/web", html=True), name="static")

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", 8000)),
        reload=os.getenv("ENVIRONMENT") == "development",
        log_level="info"
    )
