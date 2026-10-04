# !!!!!!!!!!!!Production-Ready Secure Dockerfile
# Security features:
#   - Multi-stage build (reduces final image size)
#   - Non-root user execution
#   - No unnecessary packages

# 1 build dependencies 
FROM python:3.11-slim AS builder

WORKDIR /build

# install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

# copy and install Python dependencies in /install
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- STAGE 2: Runtime (minimal, secure) ----------
FROM python:3.11-slim

LABEL maintainer="Latifa Noomen <latifanoomen1602@gmail.com>"
LABEL description="Zero-Trust Security Gateway for AI Agents"

WORKDIR /app

RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# [SECURITY] Create non-root user
RUN useradd --create-home --shell /bin/bash --uid 1000 aegisuser

# Copy installed Python packages from builder
COPY --from=builder /install /usr/local
RUN pip uninstall -y setuptools


# Copy application code
COPY --chown=aegisuser:aegisuser src/ ./src/

# [SECURITY] Switch to non-root user
USER aegisuser

# Default command (can be overridden by docker-compose)
CMD ["python", "-m", "src.agent.vulnerable_agent"]