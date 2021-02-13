import os
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Define environment variables
os.environ['KEY_VAULT_NAME'] = ''
os.environ['SECRET_NAME_COSMOS'] = ''
os.environ['AZURE_CLIENT_ID'] = '' # appId
os.environ['AZURE_CLIENT_SECRET'] = '' # password
os.environ['AZURE_TENANT_ID'] = '' # tenant

kvName = os.environ['KEY_VAULT_NAME']
kvEndpoint = f"https://{kvName}.vault.azure.net"
kvSecName = os.environ['SECRET_NAME_COSMOS']

# Create Azure Credential
cred = DefaultAzureCredential()
secret_client = SecretClient(vault_url=kvEndpoint,credential=cred)

# Get Azure Key Vault Secret
retrieved_secret = secret_client.get_secret(kvSecName)
print(f"Your secret is '{retrieved_secret.value}'.")
