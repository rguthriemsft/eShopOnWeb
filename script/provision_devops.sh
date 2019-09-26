
#!/bin/bash

usage() { echo "Usage: provision_devops.sh -u <userEmails> -t <teamNumber>" 1>&2; exit 1; }

declare organization="https://dev.azure.com/DevSecOpsOH"
declare repositoryName="eShopOnWeb"
declare templateGitHubProject="https://github.com/rguthriemsft/eShopOnWeb"
declare userEmails=""
declare acrConfigFile="acr.json"
declare spConfigFile="sp_config.json"

# Initialize parameters specified from command line
while getopts ":u:t:" arg; do
    case "${arg}" in

        u)
            userEmails=${OPTARG}
        ;;
        t)
            teamNumber=${OPTARG}
        ;;

    esac
done
shift $((OPTIND-1))

declare projectName="devsecopsohlite"${teamNumber}

echo "=========================================="
echo " VARIABLES"
echo "=========================================="
echo "organization              = "${organization}
echo "projectName               = "${projectName}
echo "repositoryName            = "${repositoryName}
echo "templateGitHubProject     = "${templateGitHubProject}
echo "userEmails                = "${userEmails}
echo "=========================================="

# Fetch the data of ACR. This section assume acr,json was created in previous step

conf=$(cat ${acrConfigFile})
acrUsername=$(echo $conf | jq .acrUserName | xargs )
acrPassword=$(echo $conf | jq .acrPassword | xargs )
acrLoginServer=$(echo $conf | jq .acrLoginServer | xargs )

# Check and add extension

az extension add --name azure-devops
az devops configure --defaults organization=$organization

# Create Project
az devops project create --name $projectName

# Add users to Administrator groups

CurrentIFS=$IFS
IFS=','
read -r -a emails <<< "$userEmails"
echo "userEmails: ${userEmails}"

for email in "${emails[@]}"
do
  echo "email: ${email}"
  projectAdministratorDescriptor=`az devops security group list -p $projectName --scope=project --query "graphGroups[?displayName=='Project Administrators'].descriptor" --output tsv`
  buildAdministratorDescriptor=`az devops security group list -p $projectName --scope=project --query "graphGroups[?displayName=='Build Administrators'].descriptor" --output tsv`
  memberDescriptor=`az devops user show --user $email --query 'user.descriptor' --output tsv`
  az devops security group membership add --group-id $projectAdministratorDescriptor --member-id $memberDescriptor
  az devops security group membership add --group-id $buildAdministratorDescriptor --member-id $memberDescriptor
done

IFS=$CurrentIFS

az repos create -p $projectName --name $repositoryName
az repos import create  --git-url $templateGitHubProject  -p $projectName -r $repositoryName

# Create Two Pipelines with configuring variables and service connection

az pipelines create --name 'eShopOnWeb.CI' --description 'Pipeline for building eShopWeb on Windows' --repository $repositoryName --branch master --repository-type tfsgit --yaml-path eShopOnWeb-CI.yml -p $projectName --skip-run
az pipelines create --name 'eShopOnWeb-Docker.CI' --description 'Pipeline for building eShopWeb on Windows' --repository $repositoryName --branch master --repository-type tfsgit --yaml-path eShopOnWeb-Docker-CI.yml -p $projectName --skip-run

# Configure the variables of ACR

az pipelines variable create --name registryUrl --value $acrLoginServer --pipeline-name eShopOnWeb-Docker.CI -p $projectName
az pipelines variable create --name registryPassword --value $acrPassword --pipeline-name eShopOnWeb-Docker.CI -p $projectName
az pipelines variable create --name registryName --value $acrUsername --pipeline-name eShopOnWeb-Docker.CI -p $projectName

# Read in SP information
sp_conf=$(cat ${spConfigFile})
acrUsername=$(echo $sp_conf | jq .acrUserName | xargs )

# Configure the servcie endpoint

export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$serviceEndpointSpPassword
az devops service-endpoint azurerm create --azure-rm-service-principal-id $serviceEndpointSpAppId --azure-rm-subscription-id $serviceEndpointSubscriptionId --azure-rm-subscription-name "${serviceEndpointSubscriptionName}" --azure-rm-tenant-id $serviceEndpointSpTenant --name ${projectName}Se --project ${projectName}
