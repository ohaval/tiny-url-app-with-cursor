# Multi-stage build for Python application
# Stage 1: Build stage - install dependencies and prepare the application
FROM python:3.11-slim as builder

# Set working directory
WORKDIR /app

# Install system dependencies needed for building Python packages
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements files
COPY requirements.txt .
COPY docker/requirements-container.txt .

# Create a virtual environment and install dependencies
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements-container.txt

# Stage 2: Runtime stage - minimal image for running the application
FROM python:3.11-slim as runtime

# Install curl for health checks
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application source code
COPY src/ ./src/
COPY docker/shorten/app.py ./

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown -R appuser:appuser /app
USER appuser

# Expose port 8000 for the web service
EXPOSE 8000

# Health check to ensure the service is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the application
CMD ["python", "app.py"]
