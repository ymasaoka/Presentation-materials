import os
import json
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

# Define additional variables
cons_level = 'Session'
database_name = 'Sample'
container_name = 'jcdug20210214'
throuput_val = 400
part_key = "/category"

kv_name = os.environ['KEY_VAULT_NAME']
kv_endpoint = f"https://{kv_name}.vault.azure.net"
secret_name = os.environ['SECRET_NAME_COSMOS']

cred = DefaultAzureCredential()
secret_client = SecretClient(vault_url=kv_endpoint, credential=cred)

retrieved_secret = secret_client.get_secret(secret_name)

# Connect to Azure Cosmos DB
cosmos_account = os.environ['COSMOS_ACCOUNT_NAME']
url = f"https://{cosmos_account}.documents.azure.com:443/"
client = CosmosClient(url, retrieved_secret.value, consistency_level=cons_level)
print(f"[{cosmos_account}] Connected successfully to Azure Cosmos DB account.")

# Create/Get Database
try:
    database = client.create_database(id=database_name, offer_throughput=throuput_val)
    print(f"[{cosmos_account}] Created successfully a database. name[{database_name}]")
except exceptions.CosmosResourceExistsError:
    database = client.get_database_client(database=database_name)
    print(f"[{cosmos_account}] Get successfully a database. name[{database_name}]")

# Create/Get Container
try:
    container = database.create_container(
        id=container_name, partition_key=PartitionKey(path=part_key)
    )
    print(f"[{cosmos_account}] Created successfully a container. name[{container_name}]")
except exceptions.CosmosResourceExistsError:
    container = database.get_container_client(container_name)
    print(f"[{cosmos_account}] Get successfully a container. name[{container_name}]")

# Upsert sample data from json
print(f"[{cosmos_account}] Loading sample data...")
data_demonslayer = json.load(open('./files/demonslayer/character.json', 'r'))

print(f"[{cosmos_account}] Upsert sample data to collection...")
for item in data_demonslayer:
    container.upsert_item(
        dict(item)
    )
print(f"[{cosmos_account}] Completed to upsert data.")

# Check data : read
print(f"[{cosmos_account}] Read all items in the container...")
# read_items = container.read_all_items() # Retuen all items in a container
read_items = container.read_all_items(max_item_count=4) # Max number of items to be returned

print(f"[{cosmos_account}] Read result:")
for item in read_items:
    print(json.dumps(item, indent=True, ensure_ascii=False))

# Check data : Query
print(f"[{cosmos_account}] Querying to the container...")
query_items = container.query_items(
    query='SELECT * FROM jcdug20210214 c WHERE c.category = @category',
    parameters=[dict(name="@category", value="main-character")]
)

print(f"[{cosmos_account}] Query result:")
for item in query_items:
    print(json.dumps(item, indent=True, ensure_ascii=False))
