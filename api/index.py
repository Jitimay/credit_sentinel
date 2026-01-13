from fastapi import FastAPI, UploadFile, File, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.responses import JSONResponse
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Boolean, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel, EmailStr, validator, Field
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
import os
import io
import json
import re
import pdfplumber

# Database setup for Vercel (SQLite for demo)
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./creditsentinel.db")
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Models
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="analyst", nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

class Loan(Base):
    __tablename__ = "loans"
    id = Column(Integer, primary_key=True, index=True)
    borrower_name = Column(String, nullable=False, index=True)
    loan_amount = Column(Float, nullable=False)
    status = Column(String, default="Active", nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    owner_id = Column(Integer, nullable=False)

class Covenant(Base):
    __tablename__ = "covenants"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    threshold = Column(Float, nullable=False)
    operator = Column(String, nullable=False)
    category = Column(String, nullable=False)
    current_value = Column(Float, nullable=True)
    status = Column(String, default="Pending", nullable=False)
    loan_id = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

# Schemas
class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    
    @validator('password')
    def validate_password(cls, v):
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain uppercase letter')
        if not re.search(r'[a-z]', v):
            raise ValueError('Password must contain lowercase letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain digit')
        return v

class LoanCreate(BaseModel):
    borrower_name: str = Field(min_length=1, max_length=255)
    loan_amount: float = Field(gt=0)

# Auth setup
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# Simple covenant engine
class CovenantEngine:
    def extract_covenants(self, text: str):
        covenants = []
        
        # Debt-to-EBITDA
        if match := re.search(r"debt.{0,20}ebitda.{0,20}(\d+\.?\d*)", text, re.I):
            covenants.append({
                "name": "Debt-to-EBITDA",
                "threshold": float(match.group(1)),
                "operator": "<=",
                "category": "Financial"
            })
        
        # Interest Coverage
        if match := re.search(r"interest.{0,20}coverage.{0,20}(\d+\.?\d*)", text, re.I):
            covenants.append({
                "name": "Interest Coverage",
                "threshold": float(match.group(1)),
                "operator": ">=",
                "category": "Financial"
            })
        
        # Current Ratio
        if match := re.search(r"current.{0,20}ratio.{0,20}(\d+\.?\d*)", text, re.I):
            covenants.append({
                "name": "Current Ratio",
                "threshold": float(match.group(1)),
                "operator": ">=",
                "category": "Financial"
            })
        
        return covenants
    
    def evaluate(self, covenant: dict, current_value: float):
        thresh = covenant["threshold"]
        op = covenant["operator"]
        
        status = "Compliant"
        if op == "<=" and current_value > thresh:
            status = "Breach"
        elif op == ">=" and current_value < thresh:
            status = "Breach"
        elif op == "<=" and current_value > (thresh * 0.9):
            status = "Warning"
        elif op == ">=" and current_value < (thresh * 1.1):
            status = "Warning"
            
        return {
            "status": status,
            "current_value": current_value,
            "threshold": thresh
        }

# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Create tables
Base.metadata.create_all(bind=engine)

# FastAPI app
app = FastAPI(title="CreditSentinel API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

engine_ai = CovenantEngine()

@app.get("/api/health")
async def health_check():
    return {"status": "healthy", "version": "1.0.0", "platform": "vercel"}

@app.post("/api/register")
async def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_pwd = get_password_hash(user.password)
    new_user = User(email=user.email, hashed_password=hashed_pwd)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return {"id": new_user.id, "email": new_user.email, "role": new_user.role}

@app.post("/api/token")
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/api/loans")
async def create_loan(loan: LoanCreate, db: Session = Depends(get_db)):
    # For demo, use user_id = 1
    db_loan = Loan(**loan.dict(), owner_id=1)
    db.add(db_loan)
    db.commit()
    db.refresh(db_loan)
    return db_loan

@app.get("/api/loans")
async def get_loans(db: Session = Depends(get_db)):
    return db.query(Loan).limit(10).all()

@app.post("/api/upload-agreement")
async def upload_agreement(loan_id: int, file: UploadFile = File(...), db: Session = Depends(get_db)):
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
    
    # Save covenants
    for cov in covenants:
        db_cov = Covenant(**cov, loan_id=loan_id)
        db.add(db_cov)
    db.commit()
    
    return {
        "filename": file.filename,
        "status": "processed",
        "covenants_found": len(covenants),
        "covenants": covenants
    }

@app.get("/api/covenants/{loan_id}")
async def get_covenants(loan_id: int, db: Session = Depends(get_db)):
    return db.query(Covenant).filter(Covenant.loan_id == loan_id).all()

# Demo data endpoint
@app.post("/api/demo-data")
async def create_demo_data(db: Session = Depends(get_db)):
    # Create demo loan
    demo_loan = Loan(
        borrower_name="Acme Corporation",
        loan_amount=5000000.0,
        owner_id=1
    )
    db.add(demo_loan)
    db.commit()
    db.refresh(demo_loan)
    
    # Create demo covenants
    demo_covenants = [
        {"name": "Debt-to-EBITDA", "threshold": 3.5, "operator": "<=", "category": "Financial", "current_value": 3.2, "status": "Compliant"},
        {"name": "Interest Coverage", "threshold": 2.0, "operator": ">=", "category": "Financial", "current_value": 2.5, "status": "Compliant"},
        {"name": "Current Ratio", "threshold": 1.25, "operator": ">=", "category": "Financial", "current_value": 1.1, "status": "Warning"}
    ]
    
    for cov_data in demo_covenants:
        covenant = Covenant(**cov_data, loan_id=demo_loan.id)
        db.add(covenant)
    
    db.commit()
    
    return {"message": "Demo data created", "loan_id": demo_loan.id}

# Export for Vercel
handler = app
