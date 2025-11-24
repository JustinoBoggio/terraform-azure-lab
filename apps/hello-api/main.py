import os

from fastapi import FastAPI, HTTPException
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

app = FastAPI()

KEYVAULT_URL = os.environ.get("KEYVAULT_URL")
SECRET_NAME = os.environ.get("SECRET_NAME", "hello-api-message")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "unknown")

if not KEYVAULT_URL:
  raise RuntimeError("KEYVAULT_URL environment variable is required")

# Use DefaultAzureCredential so it works both locally and in AKS with Workload Identity
credential = DefaultAzureCredential()
secret_client = SecretClient(vault_url=KEYVAULT_URL, credential=credential)


@app.get("/")
def read_root():
  try:
    secret = secret_client.get_secret(SECRET_NAME)
    return {
      "message": secret.value,
      "environment": ENVIRONMENT,
      "vault_url": KEYVAULT_URL,
      "secret_name": SECRET_NAME,
    }
  except Exception as ex:
    raise HTTPException(status_code=500, detail=f"Error reading secret from Key Vault: {ex}")