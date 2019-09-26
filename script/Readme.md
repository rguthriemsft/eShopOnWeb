# DevSecOps Openhack light Deployment Script

This script deploys and configures all the resources your team will need in order to complete the challenges during the OpenHack.  These resource

* **Deployed to OpsGility Subscription**
  * Azure KeyVault
  * Azure Container Registry
  * App Service
  * App Service Plan

* **Deployed to Microsoft Azure DevOps Organization (https://dev.azure.com/DevSecOpsOH)**
  * Azure DevOps Project

## How to deploy lab env

### High Level Overview

1. Az Login to Opsgility subscription

2. Provision Azure Resources in Opsgility subscription

3. Create Service Principal and save to file

4. Az Login using your Microsoft Account

5. Provision Azure DevOps resources

### 1. Az Login to Opsgility Subscription

Using the one of the credentials provided by Opsgility, execute an AZ Login

``` Bash
az login -u <username> -p <password>
```

### 2. Provision the Azure Resources in Opsgility subscription.

### 1. Deploy Azure Resources

This service principal will be used to configure a service connection in Azure DevOPs.  Before running the setup script, you **MUST**:

- execute ```az login```  ```az account set```, using your Microsoft Account in order for the script to work properly.
Also, you need to create a servcie principal for accessing Azure DevOps project, and save it as `devops_config.json` and put it on script directory which is ignored by git.
You can use `az ad sp create-for-rbac` command on the Azure DevOps subscription. the output is the format for `devops_config.json`.

### Parameters used in setup.sh script

**-l** Azure Region to deploy to (Ex. westus, eastus, centralus, etc.)

**-e** Team Number, you will get this information from your proctor.

**-o** The full url to the azure devops organization (Ex. `https://dev.azure.com/YOUR_ORGANIZATION)`

**-d** comma seperated list of emails for team members.  These emails will be provisioned in the Azure Devops Project.

### Deploy all



```bash
az account login -u <azure account name> -p <azure account password>

az account list #Find your account and note subscription id

az account set -s <subscription id>

setup.sh -l <resourceGroupLocation> -e <teamNumber> -o <AzureDevOps organization> -d <Azure DevOps UserEmails>
```

#### Deploy All Example

```bash
setup.sh -l westus -e 1 -o https://dev.azure.com/YOUR_ORGANIZATION -d abc@microsoft.com,def@microsoft.com
```

### Deploy Azure DevOps Project

This script assumes that you already execute `az login` and already have an Azure DevOps organization which this script creates a project.

```bash
provision_devops.sh -o <organization> -p <projectName> -r <repositoryName> -t <templateGitHubProject> -u <userEmails> -a <acrName>
```

#### Deploy Azure DevOps Example

```bash
bash provision_devops.sh -o https://dev.azure.com/YOUR_ORGANIZATION -p removethis -r eShopOnWeb -t https://github.com/rguthriemsft/eShopOnWeb -u abc@microsoft.com,def@microsoft.com -a tsushi05acr
```
