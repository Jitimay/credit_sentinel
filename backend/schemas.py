from pydantic import BaseModel, EmailStr, validator, Field
from typing import List, Optional
from datetime import datetime

# --- User Schemas ---
class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str = Field(min_length=8, max_length=100)
    
    @validator('password')
    def validate_password(cls, v):
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain uppercase letter')
        if not any(c.islower() for c in v):
            raise ValueError('Password must contain lowercase letter')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain digit')
        return v

class User(UserBase):
    id: int
    is_active: bool
    role: str
    created_at: datetime

    class Config:
        from_attributes = True

# --- Loan Schemas ---
class LoanBase(BaseModel):
    borrower_name: str = Field(min_length=1, max_length=255)
    loan_amount: float = Field(gt=0)

class LoanCreate(LoanBase):
    pass

class Loan(LoanBase):
    id: int
    status: str
    created_at: datetime
    owner_id: int

    class Config:
        from_attributes = True

# --- Covenant Schemas ---
class CovenantBase(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    threshold: float
    operator: str = Field(regex="^(<=|>=|<|>|=)$")
    category: str = Field(regex="^(Financial|Reporting)$")

class CovenantCreate(CovenantBase):
    loan_id: int

class Covenant(CovenantBase):
    id: int
    current_value: Optional[float] = None
    status: str
    loan_id: int
    created_at: datetime

    class Config:
        from_attributes = True

# --- Audit Log Schemas ---
class AuditLogBase(BaseModel):
    event_type: str
    details: str

class AuditLogCreate(AuditLogBase):
    user_id: Optional[int] = None

class AuditLog(AuditLogBase):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True

# --- Response Schemas ---
class FileUploadResponse(BaseModel):
    filename: str
    status: str
    message: Optional[str] = None
    
class ErrorResponse(BaseModel):
    detail: str
    error_code: Optional[str] = None
