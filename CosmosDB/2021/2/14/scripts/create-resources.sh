#!/bin/bash

# Common variables used for deployment
location='japaneast'
resourceGroupName='CosmosTutorialRG'
# Variables used to deploy Azure Cosmos DB
cosmosAccountName='samplecosmos'
defaultConsistencyLevel=Session # {BoundedStaleness, ConsistentPrefix, Eventual, Session, Strong}
enableAnalyticalStorage=true # {false, true}
enableFreeTier=false # {false, true} = Cosmos DB の無償枠 (1サブスクリプションに1つのみ作成可能)
failoverPriority=0 # {0, 1}
isZoneRedundant=false # {false, true}
# Variables used to deploy Azure Key Vault
keyVaultName='SampleKV'


# Define a variable to create a unique name
randomNum=$RANDOM
resourceGroupName=${resourceGroupName}${randomNum}
cosmosAccountName=${cosmosAccountName}${randomNum}
keyVaultName=${keyVaultName}${randomNum}

# Log-in to Azure with device code (No use browser)
echo 'Please sign-in to Azure...'

# az login -u <username> -p <password>
az login --use-device-code

echo 'Sign-in is completed.'

# Create Resource group
echo 'Creating Resource group...'

az group create --location $location \
    --name $resourceGroupName

echo 'Completed.'

# Create Azure Cosmos Account
echo 'Creating Azure Cosmos Account...'

az cosmosdb create --name $cosmosAccountName \
    --resource-group $resourceGroupName \
    --default-consistency-level $defaultConsistencyLevel \
    --enable-analytical-storage $enableAnalyticalStorage \
    --enable-free-tier $enableFreeTier \
    --enable-multiple-write-locations false \
    --enable-public-network true \
    --locations regionName=$location failoverPriority=$failoverPriority isZoneRedundant=$isZoneRedundant

echo 'Completed.'

# Create Azure Key Vault
echo 'Creating Azure Key Vault...'

az keyvault create --resource-group $resourceGroupName \
    --name $keyVaultName

echo 'Completed.'
