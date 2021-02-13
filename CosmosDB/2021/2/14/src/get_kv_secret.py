import os
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Define environment variables
os.environ['KEY_VAULT_NAME'] = ''
os.environ['SECRET_NAME_COSMOS'] = ''
os.environ['AZURE_CLIENT_ID'] = '' # appId
os.environ['AZURE_CLIENT_SECRET'] = '' # password
os.environ['AZURE_TENANT_ID'] = '' # tenant

kv_name = os.environ['KEY_VAULT_NAME']
kv_endpoint = f"https://{kv_name}.vault.azure.net"
kvSecName = os.environ['SECRET_NAME_COSMOS']

# Create Azure Credential
cred = DefaultAzureCredential()
secret_client = SecretClient(vault_url=kv_endpoint,credential=cred)

# Get Azure Key Vault Secret
retrieved_secret = secret_client.get_secret(kvSecName)
print(f"Your secret is '{retrieved_secret.value}'.")
