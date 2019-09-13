#!/bin/bash

usage() { echo "Usage: provision_web.sh -g <resourceGroupName> -n <webAppName> -l <location> -r <registryName> -i <imageName>" 1>&2; exit 1; }

declare resourceGroupName=""
declare webAppName=""
declare location=""
declare registryName=""
declare imageName=""

# Initialize parameters specified from command line
while getopts ":g:n:l:i:" arg; do
    case "${arg}" in
        g)
            resourceGroupName=${OPTARG}
        ;;
        n)
            webAppName=${OPTARG}
        ;;
        l)
            location=${OPTARG}
        ;;       
        r)
            registryName=${OPTARG}
        ;;       
        i)
            imageName=${OPTARG}
        ;;
    esac
done
shift $((OPTIND-1))

#Prompt for parameters is some required parameters are missing

if [[ -z "$resourceGroupName" ]]; then
    echo "This script will look for an existing resource group, otherwise a new one will be created "
    echo "You can create new resource groups with the CLI using: az group create "
    echo "Enter a resource group name"
    read resourceGroupName
    [[ "${resourceGroupName:?}" ]]
fi

if [[ -z "$location" ]]; then
    echo "You can lookup locations with the CLI using"

    echo "Enter WebApp location:"
    read location
fi

if [[ -z "$webAppName" ]]; then
    echo "Name of WebApp"

    echo "Enter webAppName:"
    read webAppName
fi

if [[ -z "$imageName" ]]; then
    echo "Name of Container image"

    echo "Enter Container Image Name:"
    read imageName
fi

declare appServicePlanName="${webAppName}plan"

echo "App Service Plan..."
(
    set -x
    az appservice plan create -n ${appServicePlanName} -g $resourceGroupName --is-linux -l $location --sku S1 --number-of-workers 1 > /dev/null
)

if [ $? == 0 ];
then
    echo " AppServicePlan " $appServicePlanName "created successfully..."
fi

echo "Web App..."
(
    set -x
    az webapp create -n $webAppName -g $resourceGroupName -p $appServicePlanName -i $imageName > /dev/null
)

if [ $? == 0 ];
then
    echo " WebApp " $webAppName "created successfully..."
fi

# Get the ACR credentials

#get the acr repsotiory id to tag image with.
ACR_ID=`az acr list -g $resourceGroupName --query "[].{acrLoginServer:loginServer}" --output json | jq .[].acrLoginServer | sed 's/\"//g'`

echo "ACR ID: "$ACR_ID

#Get the acr admin password and login to the registry
acrPassword=$(az acr credential show -n $registryName -o json | jq -r '[.passwords[0].value] | .[]')

echo "Configure private registry..."
(
    set -x
    az webapp config container set -n $webAppName -g $resourceGroupName -c $imageName -r $ACR_ID -u $registryName -p $acrPassword 
)

if [ $? == 0 ];
then
    echo "Configure private registry successfully..."
fi

echo "Activate the Docker container logging..."
(
    set -x
    az webapp log config -n $webAppName -g $resourceGroupName --web-server-logging filesystem > /dev/null
)

if [ $? == 0 ];
then
    echo "Activate docker container logging successfully..."
fi

