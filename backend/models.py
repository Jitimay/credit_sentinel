from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean, Text, Index
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(String(50), default="analyst", nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    loans = relationship("Loan", back_populates="owner")
    audit_logs = relationship("AuditLog", back_populates="user")

class Loan(Base):
    __tablename__ = "loans"

    id = Column(Integer, primary_key=True, index=True)
    borrower_name = Column(String(255), nullable=False, index=True)
    loan_amount = Column(Float, nullable=False)
    status = Column(String(50), default="Active", nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    owner = relationship("User", back_populates="loans")
    covenants = relationship("Covenant", back_populates="loan", cascade="all, delete-orphan")
    
    __table_args__ = (Index('idx_loan_owner_status', 'owner_id', 'status'),)

class Covenant(Base):
    __tablename__ = "covenants"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True)
    threshold = Column(Float, nullable=False)
    operator = Column(String(10), nullable=False)
    category = Column(String(50), nullable=False)
    current_value = Column(Float, nullable=True)
    status = Column(String(50), default="Pending", nullable=False)
    loan_id = Column(Integer, ForeignKey("loans.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    loan = relationship("Loan", back_populates="covenants")
    
    __table_args__ = (Index('idx_covenant_loan_status', 'loan_id', 'status'),)

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    event_type = Column(String(100), nullable=False, index=True)
    details = Column(Text, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    loan_id = Column(Integer, ForeignKey("loans.id"), nullable=True)

    user = relationship("User", back_populates="audit_logs")
    loan = relationship("Loan")
