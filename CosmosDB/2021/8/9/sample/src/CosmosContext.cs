using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;

namespace SampleCosmosApp
{
    public class CosmosContext
    {
        private IConfigurationRoot _configration;
        public Container Container { get; set; }
        public CosmosClient CosmosClient { get; set; }
        public CosmosClientOptions CosmosClientOptions { get; set; }
        public Database Database { get; set; }

        public CosmosContext()
        {
            try
            {
                this._configration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile(path: "appsettings.json")
                .Build();

                this.InitializeClientOptions();
                this.InitializeClient();
            }
            catch (Exception e)
            {
                throw e;
            }
        }

        public async Task CompareRUs(IEnumerable<RGB> rgbList)
        {
            try
            {
                RGB rgb = rgbList.ElementAt(0);
                Console.Write("Execute ReplaceItemAsync to update a item [{0}]'s field [/R]... ", rgb.id);
                ItemResponse<RGB> responseReplace = await this.Container.ReplaceItemAsync(
                    partitionKey: new PartitionKey(rgb.x),
                    id: rgb.id,
                    item: rgb
                );
                Console.Write("Complete! RU Charge for Replace a item [{0}] - {1} RU\n", responseReplace.Resource.id, responseReplace.RequestCharge);
                
                Console.Write("Execute PatchItemAsync to update a item [{0}]'s field [/R]... ", rgb.id);
                ItemResponse<RGB> responsePatch = await this.Container.PatchItemAsync<RGB>(
                    id: rgb.id,
                    partitionKey: new PartitionKey(rgb.x),
                    patchOperations: new[] { PatchOperation.Replace("/R", rgb.R) }
                );
                Console.Write("Complete! RU Charge for Patch a item [{0}] - {1} RU\n", responsePatch.Resource.id, responsePatch.RequestCharge);
            }
            catch (Exception e)
            {
                throw e;
            }
        }

        public async Task ImportMonoData(IEnumerable<RGB> rgbList)
        {
            try
            {
                Console.Write("Insert RGB data into a container [{0}}]... ", this._configration["CosmosDB:ContainerId"]);

                foreach (var rgb in rgbList)
                {
                    ItemResponse<RGB> response = await this.Container.CreateItemAsync<RGB>(
                        item: rgb,
                        partitionKey: new PartitionKey(rgb.x)
                    );
                }
                Console.Write("Completed!\n");
            }
            catch (Exception e)
            {
                throw e;
            }
        }

        private void InitializeClient()
        {
            try
            {
                Console.Write("Connecting to Cosmos account... ");
                var connStr = this._configration.GetConnectionString("CosmosDB");
                this.CosmosClient = new CosmosClient(connStr, this.CosmosClientOptions);
                Console.Write("Connected!\n");
            }
            catch (Exception e)
            {
                throw e;
            }
        }

        private void InitializeClientOptions()
        {
            try
            {
                this.CosmosClientOptions = new CosmosClientOptions()
                {
                    HttpClientFactory = () =>
                    {
                        HttpMessageHandler httpMessageHandler = new HttpClientHandler()
                        {
                            ServerCertificateCustomValidationCallback = HttpClientHandler.DangerousAcceptAnyServerCertificateValidator
                        };

                    return new HttpClient(httpMessageHandler);
                    },
                    ConnectionMode = ConnectionMode.Gateway
                };
            }
            catch (Exception e)
            {
                throw e;
            }
        }

        public async Task InitializeDatabase()
        {
            try
            {
                var databaseId = this._configration["CosmosDB:DatabaseId"];
                var throughput = Int32.Parse(this._configration["CosmosDB:DatabaseThroughput"]);
                Console.Write("Connecting to Cosmos database [{0}]... ", databaseId);
                DatabaseResponse databaseResponse = await this.CosmosClient.CreateDatabaseIfNotExistsAsync(databaseId, throughput);
                this.Database = databaseResponse.Database;
                Console.Write("Connected!\n");
            }
            catch (Exception e)
            {
                throw e;
            }
        }

        public async Task InitializeContainer()
        {
            try
            {
                var containerId = this._configration["CosmosDB:ContainerId"];
                Console.Write("Connecting to Cosmos container [{0}]... ", containerId);
                IndexingPolicy indexingPolicy = new IndexingPolicy
                {
                    IndexingMode = IndexingMode.Consistent,
                    Automatic = true,
                    IncludedPaths =
                    {
                        new IncludedPath
                        {
                            Path = "/*"
                        }
                    },
                    ExcludedPaths =
                    {
                        new ExcludedPath
                        {
                            Path = "/\"_etag\"/?"
                        }
                    }
                };

                var partitionKey = this._configration["CosmosDB:PartitionKey"];
                ContainerProperties containerProperties = new ContainerProperties(containerId, partitionKey)
                {
                    IndexingPolicy = indexingPolicy,
                };

                ContainerResponse containerResponse = await this.Database.CreateContainerIfNotExistsAsync(containerProperties);
                this.Container = containerResponse.Container;
                Console.Write("Connected!\n");
            }
            catch (Exception e)
            {
                throw e;
            }
        }

        public async Task PatchColorBlueAsync(IEnumerable<RGB> rgbList)
        {
            double totalRUs = 0;
            Console.WriteLine("Start to patch color blue... ");

            foreach (var rgb in rgbList)
            {
                ItemResponse<RGB> response = await this.Container.PatchItemAsync<RGB>(
                    id: rgb.id,
                    partitionKey: new PartitionKey(rgb.x),
                    patchOperations: new[] { PatchOperation.Replace("/B", rgb.B) }
                );

                RGB updated = response.Resource;
                Console.WriteLine("RU Charge for Patching Item by Id [{0}] - {1} RU", updated.id, response.RequestCharge);
                totalRUs += response.RequestCharge;
            }
            Console.WriteLine("Finished to patch color blue... ");
            Console.WriteLine("Total Request Units Charge for Patching Items to replace /R - {0} RU", totalRUs);
        }

        public async Task PatchColorGreenAsync(IEnumerable<RGB> rgbList)
        {
            double totalRUs = 0;
            Console.WriteLine("Start to patch color green... ");

            foreach (var rgb in rgbList)
            {
                ItemResponse<RGB> response = await this.Container.PatchItemAsync<RGB>(
                    id: rgb.id,
                    partitionKey: new PartitionKey(rgb.x),
                    patchOperations: new[] { PatchOperation.Replace("/G", rgb.G) }
                );

                RGB updated = response.Resource;
                Console.WriteLine("RU Charge for Patching Item by Id [{0}] - {1} RU", updated.id, response.RequestCharge);
                totalRUs += response.RequestCharge;
            }
            Console.WriteLine("Finished to patch color green... ");
            Console.WriteLine("Total Request Units Charge for Patching Items to replace /R - {0} RU", totalRUs);
        }

        public async Task PatchColorRedAsync(IEnumerable<RGB> rgbList)
        {
            double totalRUs = 0;
            Console.WriteLine("Start to patch color red... ");

            foreach (var rgb in rgbList)
            {
                ItemResponse<RGB> response = await this.Container.PatchItemAsync<RGB>(
                    id: rgb.id,
                    partitionKey: new PartitionKey(rgb.x),
                    patchOperations: new[] { PatchOperation.Replace("/R", rgb.R) }
                );

                RGB updated = response.Resource;
                Console.WriteLine("RU Charge for Patching Item by Id [{0}] - {1} RU", updated.id, response.RequestCharge);
                totalRUs += response.RequestCharge;
            }
            Console.WriteLine("Finished to patch color red... ");
            Console.WriteLine("Total Request Units Charge for Patching Items to replace /R - {0} RU", totalRUs);
        }
    }
}