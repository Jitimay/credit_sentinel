# CreditSentinel™ 🛡️

**AI-Powered Loan Covenant Monitoring & Early Warning System**

CreditSentinel™ is a full-stack automated platform designed to help lenders monitor complex financial covenants in loan agreements. It replaces manual analyst reviews with an intelligent, explainable, and auditable process.

## ✨ Key Features
- 🏢 **Enterprise Global Shell**: Professional navigation rail and loan context management.
- 🩺 **Loan Health Score**: 0-100 real-time health gauge calculated from covenant compliance.
- 📄 **Split-View Audit**: Interactive document viewer with side-by-side extraction verification.
- 🧪 **What-If Simulator**: Advanced stress testing with breach timeline predictions.
- 🤖 **Explainable AI**: Plain-English justifications for every covenant status and warning.

## 🚀 Getting Started

### ⚡ One-Click Launch (Recommended)
We've provided a script to start the backend (via Docker) and the Linux UI together:
```bash
./launch.sh
```

### Prerequisites (Linux)
Building the desktop app requires `libsecret-1-dev`. Install it via:
```bash
sudo apt-get install libsecret-1-dev
```

### 1. Backend (FastAPI)
The central intelligence hub handling data processing and extraction.
```bash
cd backend
pip install -r requirements.txt
python main.py
```

### 2. Frontend (Native Desktop)
Running the high-fidelity monitoring station.
```bash
cd frontend
flutter run -d linux
```

## 🛠️ Tech Stack
- **UI/UX**: Flutter Desktop, Google Fonts, FL Chart.
- **Backend**: Python, FastAPI, Pandas.
- **Audit**: In-memory event logs and explainability engine.

## 🐳 Docker Deployment
For rapid demonstration, build the consolidated web-accessible container:
```bash
docker-compose up --build
```
Access at `http://localhost:8000`.
