# CreditSentinel™ 🛡️

**AI-Powered Loan Covenant Monitoring & Early Warning System**

CreditSentinel™ is a full-stack automated platform designed to help lenders monitor complex financial covenants in loan agreements. It replaces manual analyst reviews with an intelligent, explainable, and auditable process.

## ✨ Key Features
- 📄 **Covenant Extraction**: Automatically parses legal loan documents (PDF) to identify financial thresholds.
- 📊 **Financial Analysis**: Compares borrower data (Excel/CSV) against extracted covenants in real-time.
- ⚠️ **Early Warning System**: Uses trend analysis to predict potential breaches before they happen.
- 🏢 **Desktop Dashboard**: High-fidelity Flutter dashboard for professional monitoring.
- 🐳 **Docker Ready**: One-command deployment for the entire stack.

## 🛠️ Tech Stack
- **Frontend**: Flutter (Desktop & Web)
- **Backend**: Python (FastAPI)
- **AI/NLP**: Pattern-based extraction & Rule-based evaluation engines.

## 🚀 Quick Start (Docker)
```bash
docker-compose up --build
```
Access the dashboard at `http://localhost:8000`.

## 📦 Manual Setup

### Backend
```bash
cd backend
pip install -r requirements.txt
python main.py
```

### Frontend
```bash
cd frontend
flutter run -d linux # or windows/macos
```

## 📄 License
This project is proprietary. See legal documentation for more details.
