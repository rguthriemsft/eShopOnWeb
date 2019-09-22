#!/bin/bash

usage() { echo "Usage: provision_resource.sh -s <subscriptionId> -g <resourceGroupName> -l <location> -k <keyVaultName> -r <registryName> -i <imageName> -a <storageAccountName> -w <webAppName> " 1>&2; exit 1; }

declare subscriptionId=""
declare resourceGroupName=""
declare location=""

declare keyVaultName=""

declare registryName=""
declare imageName=""

declare storageAccountName=""

declare webAppName=""

# Initialize parameters specified from command line
while getopts ":s:g:l:k:r:i:a:w:" arg; do
    case "${arg}" in
        s)
            subscriptionId=${OPTARG}
        ;;    
        g)
            resourceGroupName=${OPTARG}
        ;;
        l)
            location=${OPTARG}
        ;; 
        k)
            keyVaultName=${OPTARG}
        ;; 
        r)
            registryName=${OPTARG}
        ;;       
        i)
            imageName=${OPTARG}
        ;;
        a)
            storageAccountName=${OPTARG}
        ;;
        w)
            webAppName=${OPTARG}
        ;;
    esac
done
shift $((OPTIND-1))

echo "=========================================="
echo " VARIABLES"
echo "=========================================="
echo "subscriptionId            = "${subscriptionId}
echo "resourceGroupName         = "${resourceGroupName}
echo "location                  = "${location}
echo "keyVaultName              = "${keyVaultName}
echo "registryName              = "${registryName}
echo "imageName                 = "${imageName}
echo "storageAccountName        = "${storageAccountName}
echo "webAppName                = "${webAppName}
echo "=========================================="

# Provision KeyVault
az keyvault create -g $resourceGroupName --name $keyVaultName --location $location

# Provision ACR
az acr create -g $resourceGroupName --name $registryName --location $location --sku Basic --admin-enabled true
az acr update -n $registryName --admin-enabled true

# Build and Publish images

# Fetch the data of ACR

cred=$(az acr credential show -n $registryName)
acrUsername=$(echo $cred | jq .username | xargs )
acrPassword=$(echo $cred | jq .passwords[0].value | xargs )
conf=$(az acr show -n $registryName)
acrLoginServer=$(echo $conf | jq .loginServer | xargs )

acrImageName=${acrLoginServer}/${imageName}

pushd . 
cd ..
docker build . -t ${acrImageName}:latest
docker login -u ${acrUsername} -p ${acrPassword} ${acrLoginServer}
docker push ${acrImageName}:latest
popd

# Provision Storage Account

az storage account create --name $storageAccountName --location $location --resource-group $resourceGroupName --sku Standard_LRS

# Provision WebApp

# App Service Plan
declare appServicePlanName="${webAppName}plan"
az appservice plan create -n ${appServicePlanName} -g $resourceGroupName --is-linux -l $location --sku S1 

# WebApp
az webapp create -n $webAppName -g $resourceGroupName -p $appServicePlanName -i $acrImageName
az webapp config container set -n $webAppName -g $resourceGroupName -c $acrImageName -r $acrLoginServer -u $registryName -p $acrPassword

# Activate Docker Container Logging
az webapp log config -n $webAppName -g $resourceGroupName --web-server-logging filesystem
