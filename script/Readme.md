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

```bash
az login -u <username> -p <password>
```

### 2. Provision the Azure Resources in Opsgility subscription.

```bash
bash provision_azure_resources.sh -l westus -t <teamNumber>

```

#### Parameters used in setup.sh script

**-l** Azure Region to deploy to (Ex. westus, eastus, centralus, etc.)

**-e** Team Number, you will get this information from your proctor.

### 3. Az Login to MSFT Subscription 

```bash
az account login -u <azure account name> -p <azure account password>

az account list #Find your account and note subscription id

az account set -s <subscription id>
```

### 4. Deploy Azure DevOps project

```bash
bash provision_devops.sh -u <Comma separated usernames> -t <teamNumber>
```
