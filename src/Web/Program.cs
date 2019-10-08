using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.eShopWeb.Infrastructure.Data;
using Microsoft.eShopWeb.Infrastructure.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.eShopWeb.ApplicationCore.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;

namespace Microsoft.eShopWeb.Web
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var host = CreateWebHostBuilder(args)
                        .Build();

            using (var scope = host.Services.CreateScope())
            {
                var services = scope.ServiceProvider;
                var loggerFactory = services.GetRequiredService<ILoggerFactory>();
                try
                {
                    var serviceConfig = services.GetService<IConfiguration>();
                    var catalogContext = services.GetRequiredService<CatalogContext>();

                    CatalogContextSeed.StorageAccountConnStr = GetAppSettingsConfigValue(serviceConfig, "appsettings.Development.json", "eShopStorageAccountCS");
                    var dbSeed = services.GetRequiredService<IDbSeed>();
                    CatalogContextSeed.SeedAsync(catalogContext, loggerFactory, dbSeed).Wait();


                    var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();
                    AppIdentityDbContextSeed.SeedAsync(userManager).Wait();
                }
                catch (Exception ex)
                {
                    var logger = loggerFactory.CreateLogger<Program>();
                    logger.LogError(ex, "An error occurred seeding the DB.");
                }
            }

            host.Run();
        }

        private static string GetAppSettingsConfigValue(IConfiguration serviceConfig, string configFileName, string configKey)
        {

            var e = (((ConfigurationRoot)serviceConfig).Providers).GetEnumerator();
            while (e.MoveNext())
            {
                if(e.Current.GetType() == typeof(Extensions.Configuration.Json.JsonConfigurationProvider))
                {
                    var config = (Extensions.Configuration.Json.JsonConfigurationProvider)e.Current;
                    if (config.Source.Path.Equals(configFileName, StringComparison.OrdinalIgnoreCase))
                    {
                        if (config.TryGet(configKey, out string value))
                            return value;
                    }
                }
            }
            return string.Empty;
        }

        public static IWebHostBuilder CreateWebHostBuilder(string[] args) =>
            WebHost.CreateDefaultBuilder(args)
                .UseStartup<Startup>();
    }
}
