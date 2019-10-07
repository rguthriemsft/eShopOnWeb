using Microsoft.eShopWeb.ApplicationCore.Entities;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Azure.Storage;
using Microsoft.Azure.Storage.File;
using Newtonsoft.Json;

namespace Microsoft.eShopWeb.Infrastructure.Data
{
    public class CatalogContextSeed
    {
        public static async Task SeedAsync(CatalogContext catalogContext,
            ILoggerFactory loggerFactory, int? retry = 0)
        {
            int retryForAvailability = retry.Value;
            try
            {
                // TODO: Only run this if using a real database
                // context.Database.Migrate();

                if (!catalogContext.CatalogBrands.Any())
                {
                    catalogContext.CatalogBrands.AddRange(
                        GetPreconfiguredCatalogBrands());

                    await catalogContext.SaveChangesAsync();
                }

                if (!catalogContext.CatalogTypes.Any())
                {
                    catalogContext.CatalogTypes.AddRange(
                        GetPreconfiguredCatalogTypes());

                    await catalogContext.SaveChangesAsync();
                }

                if (!catalogContext.CatalogItems.Any())
                {
                    catalogContext.CatalogItems.AddRange(
                        GetPreconfiguredItems());

                    await catalogContext.SaveChangesAsync();
                }
            }
            catch (Exception ex)
            {
                if (retryForAvailability < 10)
                {
                    retryForAvailability++;
                    var log = loggerFactory.CreateLogger<CatalogContextSeed>();
                    log.LogError(ex.Message);
                    await SeedAsync(catalogContext, loggerFactory, retryForAvailability);
                }
            }
        }

        static IEnumerable<CatalogBrand> GetPreconfiguredCatalogBrands()
        {
            var fileContent = LoadAzureStorafeFileContents("CatalogBrands.json");
            if (fileContent == string.Empty)
                return new List<CatalogBrand>();

            return JsonConvert.DeserializeObject<List<CatalogBrand>>(fileContent);
        }

        static IEnumerable<CatalogType> GetPreconfiguredCatalogTypes()
        {
            var fileContent = LoadAzureStorafeFileContents("CatalogTypes.json");
            if (fileContent == string.Empty)
                return new List<CatalogType>();

            return JsonConvert.DeserializeObject<List<CatalogType>>(fileContent);
        }

        static IEnumerable<CatalogItem> GetPreconfiguredItems()
        {
            var fileContent = LoadAzureStorafeFileContents("CatalogItems.json");
            if (fileContent == string.Empty)
                return new List<CatalogItem>();

            return JsonConvert.DeserializeObject<List<CatalogItem>>(fileContent);
        }

        static string LoadAzureStorafeFileContents(string fileName)
        {
            var storageAccountCS = "REPLACEWITHCS";
            CloudStorageAccount storageAccount = CloudStorageAccount.Parse(storageAccountCS);

            // Create a CloudFileClient object for credentialed access to Azure Files.
            CloudFileClient fileClient = storageAccount.CreateCloudFileClient();
            CloudFileShare share = fileClient.GetShareReference("eshop");

            //// Ensure that the share exists.
            if (share.Exists())
            {
                // Get a reference to the root directory for the share.
                CloudFileDirectory rootDir = share.GetRootDirectoryReference();

                //Get a reference to the file we created previously.
                CloudFile file = rootDir.GetFileReference(fileName);

                // Ensure that the file exists.
                if (file.Exists())
                {
                    //download file content
                    return file.DownloadTextAsync().Result;
                }
            }

            return string.Empty;
        }
    }
}
