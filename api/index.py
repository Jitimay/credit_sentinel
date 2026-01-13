from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import json
import re

app = FastAPI(title="CreditSentinel API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage for demo
loans_db = []
covenants_db = []

class LoanCreate(BaseModel):
    borrower_name: str
    loan_amount: float

@app.get("/api/health")
async def health_check():
    return {"status": "healthy", "version": "1.0.0", "platform": "vercel"}

@app.post("/api/loans")
async def create_loan(loan: LoanCreate):
    loan_id = len(loans_db) + 1
    new_loan = {
        "id": loan_id,
        "borrower_name": loan.borrower_name,
        "loan_amount": loan.loan_amount,
        "status": "Active"
    }
    loans_db.append(new_loan)
    return new_loan

@app.get("/api/loans")
async def get_loans():
    return loans_db

@app.post("/api/demo-data")
async def create_demo_data():
    # Clear existing data
    loans_db.clear()
    covenants_db.clear()
    
    # Create demo loan
    demo_loan = {
        "id": 1,
        "borrower_name": "Acme Corporation",
        "loan_amount": 5000000.0,
        "status": "Active"
    }
    loans_db.append(demo_loan)
    
    # Create demo covenants
    demo_covenants = [
        {
            "id": 1,
            "loan_id": 1,
            "name": "Debt-to-EBITDA",
            "threshold": 3.5,
            "operator": "<=",
            "current_value": 3.2,
            "status": "Compliant"
        },
        {
            "id": 2,
            "loan_id": 1,
            "name": "Interest Coverage",
            "threshold": 2.0,
            "operator": ">=",
            "current_value": 2.5,
            "status": "Compliant"
        },
        {
            "id": 3,
            "loan_id": 1,
            "name": "Current Ratio",
            "threshold": 1.25,
            "operator": ">=",
            "current_value": 1.1,
            "status": "Warning"
        }
    ]
    covenants_db.extend(demo_covenants)
    
    return {
        "message": "Demo data created successfully",
        "loan_id": 1,
        "covenants_count": len(demo_covenants)
    }

@app.get("/api/covenants/{loan_id}")
async def get_covenants(loan_id: int):
    return [c for c in covenants_db if c["loan_id"] == loan_id]

# Export for Vercel
handler = app
