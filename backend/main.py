from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from covenant_engine import CovenantEngine
from data_processor import DataProcessor
import io
import uvicorn
import os

app = FastAPI(title="CreditSentinel API")

# Enable CORS for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

engine = CovenantEngine()
processor = DataProcessor()

# Serve Flutter Web build if it exists
if os.path.exists("../frontend/build/web"):
    app.mount("/", StaticFiles(directory="../frontend/build/web", html=True), name="static")

# Store state in memory (for prototype)
active_covenants = []
financial_data = {}

@app.get("/")
async def root():
    return {"message": "CreditSentinel AI Engine is running"}

@app.post("/upload-agreement")
async def upload_agreement(file: UploadFile = File(...)):
    content = await file.read()
    # In a real app, we'd use a PDF parser here. For now, we simulate extraction.
    text = content.decode("utf-8", errors="ignore") 
    global active_covenants
    active_covenants = engine.extract_covenants(text)
    return {"filename": file.filename, "status": "processed", "covenants": active_covenants}

@app.post("/upload-financials")
async def upload_financials(file: UploadFile = File(...)):
    content = await file.read()
    df = processor.normalize_financials(content, file.filename)
    ratios = processor.calculate_ratios(df)
    
    report = []
    for cov in active_covenants:
        val = ratios.get(cov["name"])
        if val is not None:
            evaluation = engine.evaluate(cov, val)
            report.append({
                "name": cov["name"],
                **evaluation
            })
            
    return {
        "filename": file.filename,
        "summary": report,
        "ratios": ratios
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
