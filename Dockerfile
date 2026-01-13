# Stage 1: Build Flutter Web
FROM debian:bookworm-slim AS flutter-builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter config --enable-web --no-analytics
RUN flutter doctor

# Copy frontend and build
WORKDIR /app/frontend
COPY frontend/pubspec.* ./
RUN flutter pub get
COPY frontend .
RUN flutter build web --release

# Stage 2: Production Backend
FROM python:3.11-slim AS production

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libmagic1 curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Install Python dependencies
COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY backend ./backend

# Copy built frontend from Stage 1
COPY --from=flutter-builder /app/frontend/build/web ./frontend/build/web

# Create logs directory
RUN mkdir -p logs && chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# Run backend
WORKDIR /app/backend
CMD ["python", "-m", "uvicorn", "main_prod:app", "--host", "0.0.0.0", "--port", "8000"]
