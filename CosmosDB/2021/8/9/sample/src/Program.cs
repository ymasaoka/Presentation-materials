using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Azure.Cosmos;

namespace SampleCosmosApp
{
    class Program
    {
        static void Main(string[] args)
        {
            try
            {
                MainAsync(args).Wait();
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
            }
        }

        static async Task MainAsync(string[] args)
        {
            try
            {
                // Connect and Initialize Cosmos DB environment
                var cosmosContext = new CosmosContext();
                await cosmosContext.InitializeDatabase();
                await cosmosContext.InitializeContainer();
                // Import RGB data of Mona Liza
                var jsonContext = new JsonContext();
                await jsonContext.InitializeRGBData();

                var arg = (args.Length > 0 ? args[0] : string.Empty);
                switch (arg)
                {
                    case "--red":
                        await cosmosContext.PatchColorRedAsync(jsonContext.RGBList);
                        break;
                    case "--green":
                        await cosmosContext.PatchColorGreenAsync(jsonContext.RGBList);
                        break;
                    case "--blue":
                        await cosmosContext.PatchColorBlueAsync(jsonContext.RGBList);
                        break;
                    case "--init":
                        await jsonContext.InitializeRGBMono();
                        await cosmosContext.ImportMonoData(jsonContext.RGBList);
                        break;
                    case "--compare":
                        await cosmosContext.CompareRUs(jsonContext.RGBList);
                        break;
                    default:
                        Console.WriteLine("\nEnter the permitted arguments together to run. [--red|--green|--blue|--init].\n");
                        break;
                }
            }
            catch (Exception e)
            {
                throw e;
            }
        }
    }
}
