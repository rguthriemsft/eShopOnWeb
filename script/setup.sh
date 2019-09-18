#!/bin/bash
# Deploy whole infrastructure of DevSecOps openhack.

IFS=$'\n\t'

echo "$@"

usage() { echo "Usage setup.sh -i <subscriptionId> -l <resourceGroupLocation> -n <teamName> -e <teamNumber> -u <azureUserName> -p <azurePassword> -t <tenantId> -o <AzureDevOps organization> -d <Azure DevOps UserEmails>" 1>&2; exit 1; }


declare subscriptionId=""
declare resourceGroupLocation=""
declare teamName=""
declare teamNumber=""

declare devopsOrganization=""
declare devopsUserEmails=""

while getopts ":i:l:n:e:q:r:t:u:p:j:o:d" arg; do
    case "${arg}" in
        i)
            subscriptionId=${OPTARG}
        ;;
        l)
            resourceGroupLocation=${OPTARG}
        ;;
        n)
            teamName=${OPTARG}
        ;;
        e)
            teamNumber=${OPTARG}
        ;;
        u)
            azureUserName=${OPTARG}
        ;;
        p)
            azurePassword=${OPTARG}
        ;;
        t)
            tenantId=${OPTARG}
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

randomChar() {
    s=abcdefghijklmnopqrstuvxwyz0123456789
    p=$(( $RANDOM % 36))
    echo -n ${s:$p:1}
}

randomNum() {
    echo -n $(( $RANDOM % 10 ))
}

randomCharUpper() {
    s=ABCDEFGHIJKLMNOPQRSTUVWXYZ
    p=$(( $RANDOM % 26))
    echo -n ${s:$p:1}
}

if [[ -z "$teamNumber" ]]; then
    echo "Using a random team number since not specified."
    teamNumber="$(randomChar;randomChar;randomChar;randomNum;)"
fi

declare resourceGroupTeam = "${teamName}${teamNumber}rg";
declare keyVaultName="${teamName}${teamNumber}kv";
declare registryName="${teamName}${teamNumber}acr";
declare webAppName="${teamName}${teamNumber}web";
declare storageAccountName="${teamName}${teamNumber}sa"

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
echo "tenantId"                 = "${tenantId}"
echo "=========================================="

#login to azure using your credentials
echo "Username: $azureUserName"
echo "Password: $azurePassword"

if [[ "$tenantId" == "noSP" ]]; then
    echo "Command will be az login --username=$azureUserName --password=$azurePassword"
    az login --username=$azureUserName --password=$azurePassword
else
        echo "Command will be az login --username=$azureUserName --password=$azurePassword --tenant=$tenantId"
    az login  --service-principal --username=$azureUserName --password=$azurePassword --tenant=$tenantId
fi

#set the default subscription id
echo "Setting subscription to $subscriptionId..."

az account set --subscription $subscriptionId

declare tenantId=$(az account show -s ${subscriptionId} --query tenantId -o tsv)

# create resourceGroup

az group create -n $resourceGroupTeam -l $resourceGroupLocation

# Provision resource

bash ./provision_resource.sh -s $subscriptionId -g $resourceGroupTeam -l $resourceGroupLocation -k $keyVaultName -r $registryName -i eshoponweb -a $storageAccountName -w $webAppName

# Provision Azure DevOps

bash ./provision_devops.sh -o $devopsOrganization -p DevSecOps -r eShopOnWeb -t https://github.com/rguthriemsft/eShopOnWeb -u <userEmails> -a $registryName
