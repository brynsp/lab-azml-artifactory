# Dockerfile for Contoso Lab Sample ML Model
# This creates a minimal container for testing the Artifactory -> ACR -> Azure ML workflow

FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies for Azure ML
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY score.py /app/
COPY model_utils.py /app/

# Set environment variables
ENV PYTHONPATH=/app
ENV MODEL_NAME=contoso-sample-model
ENV MODEL_VERSION=1.0.0

# Expose port for Azure ML inference server
EXPOSE 5001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5001/health || exit 1

# Default command (Azure ML will override this)
CMD ["python", "score.py"]