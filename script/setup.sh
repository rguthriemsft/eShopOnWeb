#!/bin/bash
# Deploy whole infrastructure of DevSecOps openhack.

IFS=$'\n\t'

echo "$@"

usage() { echo "Usage setup.sh -i <subscriptionId> -l <resourceGroupLocation> -n <teamName> -e <teamNumber> -u <azureUserName> -p <azurePassword> -t <tenantId>" 1>&2; exit 1; }


declare subscriptionId=""
declare resourceGroupLocation=""
declare teamName=""
declare teamNumber=""

while getopts ":i:l:n:e:q:r:t:u:p:j:" arg; do
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


# Create ACR

# Create KeyVault 
# Create Web App for Container 

# Create Storage Account
