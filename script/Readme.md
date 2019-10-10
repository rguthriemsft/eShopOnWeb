# DevSecOps OpenHack Light deployment script

This script deploys and configures all the resources your team will need in order to complete the challenges during the OpenHack. These resources:

* **Deployed to Opsgility Subscription**
  * Azure Key Vault
  * Azure Container Registry
  * App Service
  * App Service Plan

* **Deployed to Microsoft Azure DevOps Organization (<https://dev.azure.com/DevSecOpsOH>)**
  * Azure DevOps Project

## How to deploy lab env

### High Level Overview

1. Az Login to Opsgility subscription

2. Provision Azure Resources in Opsgility subscription

3. Az Login using your Microsoft Account

4. Provision Azure DevOps resources

### 1. Az Login to Opsgility Subscription

Using the one of the credentials provided by Opsgility, execute an AZ Login (For testing you can either your internal subscription or MSDN subscription)

```bash
#For OpsGility use
az login -u <username> -p <password>

#For Internal or MSDN use (Will take you to browser to complete sign-in)
az login
```

### 2. Provision the Azure Resources in Opsgility subscription

This assumes you are in the root of eShopOnWeb project.

```bash
cd script
./provision_azure_resources.sh -l westus -t <teamNumber>
```

Once this script completes, two files will be present in the scripts directory. They are acr.json and subscription.json. These files contain information needed during the provisioning of DevOps resources in step 4. Do not delete them. Keeping a copy of these files after the provisioning has completed will save time during some of the challenges by making information quickly available to the team.

### 3. Az login to your MSFT Account

Once you have provisioned the infrastructure, you will need to do a second az login to login with your Microsoft Account.

``` Bash
az login #should open a browser where you can sign-in with your MSFT account.

#If you have multiple subscriptions, you need to set the correct subscription.
az account list
az account set -s <subscription id>

az account show
```

### 4. Deploy Azure DevOps project

Finally, provision the DevOps project by running the script below. You will pass the same team number and a **comma-separated list** of emails for users that should be provisioned into the project.

```bash
bash provision_devops.sh -u <Comma separated usernames> -t <teamNumber>
```

Example: Provision the project for Volker Will and Richard Guthrie who are in team 1

```bash
bash provision_devops.sh -u rguthrie@microsoft.com,volkerw@microsoft.com -t 1

```

### 5. Change ConnectionString in code

Go to eShopOnWeb repo on the project that you provisioned at step 4.

* Create a branch in the repo using git

* Find `../src/Infrastructure/Data/StorageAcctDbSeed.cs` and Search for `REPLACEWITHCS`.

* Replace `REPLACEWITHCS` with the connection string that you can find in `subscription.json` in your machine.

* Merge the branch into **master** branch.
