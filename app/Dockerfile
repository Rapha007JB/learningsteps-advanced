# Single-stage build
FROM python:3.14-slim

# Update base image packages to fix security vulnerabilities
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# Non-root user with a fixed UID/GID (1000) so it matches runAsUser in the Kubernetes manifest
RUN groupadd --gid 1000 appuser && useradd --uid 1000 --gid appuser --create-home appuser

WORKDIR /app

# Copy requirements first for layer caching
COPY requirements.txt .

# Install Python dependencies, then remove pip itself: the running API does not need it,
# and pip bundles its own copies of msgpack, urllib3 and setuptools that scanners flag.
RUN pip install --no-cache-dir -r requirements.txt \
 && pip uninstall -y pip

# Copy application code
COPY . .

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

USER 1000

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health').read()"

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
