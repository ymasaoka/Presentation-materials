import os
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.cosmos import exceptions, CosmosClient, PartitionKey

# Define environment variables
os.environ['KEY_VAULT_NAME'] = ''
os.environ['SECRET_NAME_COSMOS'] = ''
os.environ['COSMOS_ACCOUNT_NAME'] = ''
os.environ['AZURE_CLIENT_ID'] = '' # appId
os.environ['AZURE_CLIENT_SECRET'] = '' # password
os.environ['AZURE_TENANT_ID'] = '' # tenant

kv_name = os.environ['KEY_VAULT_NAME']
kv_endpoint = f"https://{kv_name}.vault.azure.net"
secret_name = os.environ['SECRET_NAME_COSMOS']

cred = DefaultAzureCredential()
secret_client = SecretClient(vault_url=kv_endpoint, credential=cred)

retrieved_secret = secret_client.get_secret(secret_name)

# Connect to Azure Cosmos DB
cosmos_account = os.environ['COSMOS_ACCOUNT_NAME']
url = f"https://{cosmos_account}.documents.azure.com:443/"
client = CosmosClient(url, retrieved_secret.value)
print(f"[{cosmos_account}] Connected successfully to Azure Cosmos DB account.")
