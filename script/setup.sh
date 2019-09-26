#!/bin/bash
# Deploy whole infrastructure of DevSecOps openhack.

IFS=$'\n\t'

echo "$@"

usage() { echo "Usage setup.sh -l <resourceGroupLocation> -e <teamNumber> -o <AzureDevOps organization> -d <Azure DevOps UserEmails>" 1>&2; exit 1; }

declare resourceGroupLocation=""
declare teamName="devsecopsohlite"
declare teamNumber=""

declare devopsOrganization=""
declare devopsUserEmails=""

while getopts ":l:e:o:d:" arg; do
    case "${arg}" in
        l)
            resourceGroupLocation=${OPTARG}
        ;;
        e)
            teamNumber=${OPTARG}
        ;;
        o)
            devopsOrganization=${OPTARG}
        ;;
        d)
            devopsUserEmails=${OPTARG}
        ;;
    esac
done

shift $((OPTIND-1))



declare resourceGroupTeam="${teamName}${teamNumber}rg";
declare keyVaultName="${teamName}${teamNumber}kv";
declare registryName="${teamName}${teamNumber}acr";
declare webAppName="${teamName}${teamNumber}web";
declare storageAccountName="${teamName}${teamNumber}sa"
declare devopsProjectName="${teamName}${teamNumber}";

declare tenantId=$(az account show --query tenantId -o tsv)
declare subscriptionId=$(az account show --query id -o tsv)

echo "=========================================="
echo " VARIABLES"
echo "=========================================="
echo "subscriptionId            = "${subscriptionId}
echo "resourceGroupLocation     = "${resourceGroupLocation}
echo "teamName                  = "${teamName}
echo "teamNumber                = "${teamNumber}
echo "keyVaultName              = "${keyVaultName}
echo "resourceGroupTeam         = "${resourceGroupTeam}
echo "registryName              = "${registryName}
echo "tenantId                  = "${tenantId}
echo "devopsOrganization        = "${devopsOrganization}
echo "devopsUserEmails          = "${devopsUserEmails}
echo "devopsProjectName         = "${devopsProjectName}
echo "storageAccountName        = "${storageAccountName}
echo "webAppName                = "${webAppName}
echo "=========================================="

# create resourceGroup

az group create -n $resourceGroupTeam -l $resourceGroupLocation

# Provision resource

bash ./provision_resource.sh -s $subscriptionId -g $resourceGroupTeam -l $resourceGroupLocation -k $keyVaultName -r $registryName -i eshoponweb -a $storageAccountName -w $webAppName
