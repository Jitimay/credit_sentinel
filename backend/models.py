from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    role = Column(String, default="analyst") # admin, analyst
    is_active = Column(Boolean, default=True)

    audit_logs = relationship("AuditLog", back_populates="user")

class Covenant(Base):
    __tablename__ = "covenants"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    threshold = Column(Float)
    operator = Column(String) # >, <, >=, <=
    category = Column(String) # Financial, Reporting
    current_value = Column(Float, nullable=True)
    status = Column(String, default="Pending") # Compliant, Warning, Breach
    
    # In a real app, link to a Loan model
    # loan_id = Column(Integer, ForeignKey("loans.id"))

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    event_type = Column(String, index=True)
    details = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    user = relationship("User", back_populates="audit_logs")
