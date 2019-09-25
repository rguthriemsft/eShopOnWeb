# DevSecOps Openhack light Deployment Script

This script deploys and configures all the resources your team will need in order to complete the challenges during the OpenHack.

* Azure KeyVault
* Azure Container Registry
* App Service
* App Service Plan
* Azure DevOps Project

## How to use

You can find the deployment scripts on [eShopOnWeb](https://dev.azure.com/csedevops/DevSecOps/_git/eShopOnWeb?path=%2Fscript&version=GBmaster).
Clone the repo and go to the `script` directory.

```bash
git clone https://csedevops@dev.azure.com/csedevops/DevSecOps/_git/eShopOnWeb
cd eShopOnWeb/script
```

### Parameters used in setup.sh script

**-l** Azure Region to deploy to (Ex. westus, eastus, centralus, etc.)

**-e** Team Number, you will get this information from your proctor.

**-o** The full url to the azure devops organization (Ex. `https://dev.azure.com/YOUR_ORGANIZATION)`

**-d** comma seperated list of emails for team members.  These emails will be provisioned in the Azure Devops Project.

### Deploy all

Before running the setup script, you **MUST** execute ```az login``` and ```az account set``` in order for the script to work properly.
Also, you need to create a servcie principal for accessing Azure DevOps project, and save it as `devops_config.json` and put it on script directory which is ignored by git.
You can use `az ad sp create-for-rbac` command on the Azure DevOps subscription. the output is the format for `devops_config.json`. 

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
