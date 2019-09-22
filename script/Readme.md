# DevSecOps Openhack light Deployment Script

This script deploys and configures all resources of OpenHack light.

* Azure KeyVault
* Azure Container Registry
* App Service
* App Service Plan
* Azure DevOps Project

# How to use

## Deploy all

```bash
setup.sh -i <subscriptionId> -l <resourceGroupLocation> -n <teamName> -e <teamNumber> -u <azureUserName> -p <azurePassword> -t <tenantId> -o <AzureDevOps organization> -d <Azure DevOps UserEmails>
```

### Example

```bash
bash setup.sh -i <subscriptionId> -l westus -n tsushitest -e 1 -u <service principal name>  -p <service principal password> -t <servcie principal tenantId> -o https://dev.azure.com/YOUR_ORGANIZATION -d abc@microsoft.com,def@microsoft.com
```
## Deploy Azure DevOps Project

This script assumes that you already execute `az login` and already have an Azure DevOps organization which this script creates a project.

```bash
provision_devops.sh -o <organization> -p <projectName> -r <repositoryName> -t <templateGitHubProject> -u <userEmails> -a <acrName> 
```

### Example

```bash
bash provision_devops.sh -o https://dev.azure.com/YOUR_ORGANIZATION -p removethis -r eShopOnWeb -t https://github.com/rguthriemsft/eShopOnWeb -u abc@microsoft.com,def@microsoft.com -a tsushi05acr
```
