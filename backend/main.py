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
audit_logs = [
    {"timestamp": "2025-12-30 10:00:00", "event": "System initialized", "user": "System"},
]

@app.get("/logs")
async def get_logs():
    return audit_logs

@app.post("/simulate")
async def simulate(data: dict):
    # Data format: {"ebitda_change": -0.1, "debt_change": 0.0}
    # For simplicity, we adjust the last known ratios
    ebitda_factor = 1.0 + data.get("ebitda_change", 0.0)
    debt_factor = 1.0 + data.get("debt_change", 0.0)
    
    simulation_results = []
    # Base ratios (mocked for prototype)
    base_ratios = {"Debt-to-EBITDA": 3.2, "Interest Coverage": 2.5, "Current Ratio": 1.2}
    
    for cov in active_covenants or engine.extract_covenants(""):
        name = cov["name"]
        val = base_ratios.get(name, 1.0)
        
        if name == "Debt-to-EBITDA":
            sim_val = round(val * (debt_factor / ebitda_factor), 2)
        elif name == "Interest Coverage":
            sim_val = round(val * ebitda_factor, 2)
        else:
            sim_val = val
            
        eval_res = engine.evaluate(cov, sim_val)
        simulation_results.append({
            "name": name,
            **eval_res,
            "explanation": engine.generate_explanation(cov, eval_res)
        })
    
    audit_logs.append({
        "timestamp": "2025-12-30 16:40:00",
        "event": f"What-if simulation run (EBITDA: {ebitda_factor}x, Debt: {debt_factor}x)",
        "user": "Analyst"
    })
    return simulation_results

@app.post("/upload-agreement")
async def upload_agreement(file: UploadFile = File(...)):
    content = await file.read()
    text = content.decode("utf-8", errors="ignore") 
    global active_covenants
    active_covenants = engine.extract_covenants(text)
    
    audit_logs.append({
        "timestamp": "2025-12-30 16:38:00",
        "event": f"New loan agreement uploaded: {file.filename}",
        "user": "Analyst"
    })
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
                **evaluation,
                "explanation": engine.generate_explanation(cov, evaluation)
            })
            
    audit_logs.append({
        "timestamp": "2025-12-30 16:39:00",
        "event": f"Financial statements analyzed: {file.filename}",
        "user": "Analyst"
    })
    return {
        "filename": file.filename,
        "summary": report,
        "ratios": ratios
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
