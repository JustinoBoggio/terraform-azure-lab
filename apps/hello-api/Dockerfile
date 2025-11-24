FROM python:3.12-slim

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir \
    fastapi \
    "uvicorn[standard]" \
    azure-identity \
    azure-keyvault-secrets

# Copy application code
COPY main.py .

# Expose the HTTP port
EXPOSE 80

# Run the FastAPI app with Uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]