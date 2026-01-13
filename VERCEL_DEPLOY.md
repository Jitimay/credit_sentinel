# CreditSentinel™ - Vercel Deployment

## Quick Deploy to Vercel

1. **Install Vercel CLI**:
```bash
npm i -g vercel
```

2. **Deploy from this directory**:
```bash
cd /home/josh/Antigravity/CreditSentinel
vercel --prod
```

3. **Set Environment Variables** in Vercel Dashboard:
- `SECRET_KEY`: your-secret-key-here
- `DATABASE_URL`: sqlite:///./creditsentinel.db
- `GEMINI_API_KEY`: your-gemini-api-key (OpenRouter key)
- `GEMINI_MODEL`: google/gemini-2.0-flash-exp:free
- `OPENROUTER_BASE_URL`: https://openrouter.ai/api/v1

## Test the Deployment

Once deployed, test these endpoints:

- **Frontend**: `https://your-app.vercel.app`
- **Health Check**: `https://your-app.vercel.app/api/health`
- **Demo Data**: Click "Create Demo Data" button in the UI

## Features Available

✅ **Backend API** - FastAPI with SQLite database
✅ **Frontend** - Flutter web app with professional UI
✅ **Demo Data** - One-click loan and covenant creation
✅ **Covenant Engine** - AI-powered document parsing
✅ **File Upload** - PDF and Excel processing
✅ **Real-time Status** - Health monitoring

## API Endpoints

- `GET /api/health` - System health check
- `POST /api/register` - User registration
- `POST /api/token` - User login
- `POST /api/loans` - Create loan
- `GET /api/loans` - List loans
- `POST /api/upload-agreement` - Upload loan agreement
- `GET /api/covenants/{loan_id}` - Get loan covenants
- `POST /api/demo-data` - Create demo data

## Demo Workflow

1. Visit your Vercel URL
2. Click "Create Demo Data"
3. View the created loan (Acme Corporation)
4. Backend processes covenant monitoring automatically

**Perfect for LMA Edge Hackathon demonstration!** 🏆
