# Python app container for churn-prediction (lean, v0.3.0)
FROM python:3.11-slim

# Smaller image, immediate logs, no pip cache
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app

# OS deps: build tools (native wheels) + psql client (debug/health)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential postgresql-client \
  && rm -rf /var/lib/apt/lists/*

# Install ONLY minimal runtime deps first for better layer caching
COPY requirements.txt .
RUN python -m pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Copy ONLY runtime code (keeps image small; repo is volume-mounted in dev)
COPY src/ ./src

# Drop root
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Default: lightweight health check (compose overrides with `sleep infinity` in dev)
CMD ["python", "-m", "src.app", "health"]
