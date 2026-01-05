from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime

# --- User Schemas ---
class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool
    role: str

    class Config:
        orm_mode = True

# --- Covenant Schemas ---
class CovenantBase(BaseModel):
    name: str
    threshold: float
    operator: str
    category: str

class CovenantCreate(CovenantBase):
    pass

class Covenant(CovenantBase):
    id: int
    current_value: Optional[float] = None
    status: str

    class Config:
        orm_mode = True

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
        orm_mode = True
