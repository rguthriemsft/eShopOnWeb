
#!/bin/bash

usage() { echo "Usage: provision_devops.sh -o <organization> -p <projectName> -r <repositoryName> -t <templateGitHubProject> -u <userEmails> -a <acrName> -d <devops config file> " 1>&2; exit 1; }

declare organization="" 
declare projectName=""
declare repositoryName=""
declare templateGitHubProject=""
declare userEmails=""
declare acrName=""
declare devopsConfigFile=""

# Initialize parameters specified from command line
while getopts ":o:p:r:t:u:a:d:" arg; do
    case "${arg}" in
        o)
            organization=${OPTARG}
        ;;
        p)
            projectName=${OPTARG}
        ;;
        r)
            repositoryName=${OPTARG}
        ;;       
        t)
            templateGitHubProject=${OPTARG}
        ;;       
        u)
            userEmails=${OPTARG}
        ;;
        a)
            acrName=${OPTARG}
        ;;        
        d)
            devopsConfigFile=${OPTARG}
        ;;  
    esac
done
shift $((OPTIND-1))

echo "=========================================="
echo " VARIABLES"
echo "=========================================="
echo "organization              = "${organization}
echo "projectName               = "${projectName}
echo "repositoryName            = "${repositoryName}
echo "templateGitHubProject     = "${templateGitHubProject}
echo "userEmails                = "${userEmails}
echo "acrName                   = "${acrName}
echo "servicePrincipalFile      = "${servicePrincipprojectNamealFile}
echo "=========================================="

# Fetch the data of ACR. This section assume that az login is executed for resource deployment.

cred=$(az acr credential show -n $acrName)
acrUsername=$(echo $cred | jq .username | xargs )
acrPassword=$(echo $cred | jq .passwords[0].value | xargs )
conf=$(az acr show -n $acrName)
acrLoginServer=$(echo $conf | jq .loginServer | xargs )

# Create Service Principal of the current subscription
# This command works for interactive login. 
# If you use service prinicpal for the login, you need to add owner role with API permission 
# for Microsoft Graph Application.ReadWrite.All and ApplicationReadWriteOwnedBy on your AD. 

serviceEndpointSp=$(az ad sp create-for-rbac)
serviceEndpointSpAppId=$(echo $serviceEndpointSp | jq .appId | xargs )
serviceEndpointSpPassword=$(echo $serviceEndpointSp | jq .password | xargs )
serviceEndpointSpTenant=$(echo $serviceEndpointSp | jq .tenant | xargs )
serviceEndpointSubscriptionId=$(az account show --query id -o tsv)
serviceEndpointSubscriptionName=$(az account show --query name -o tsv)

# Login to Azure DevOps project

devopsSp=$(cat ${devopsConfigFile})
devopsSpName=$(echo $devopsSp | jq .name | xargs )
devopsSpPassword=$(echo $devopsSp | jq .password | xargs )
devopsSpTenant=$(echo $devopsSp | jq .tenant | xargs )

az login --service-prinicpal --username=$devopsSpName --password=$devopsSpPassword --tenant=$devopsSpTenant

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

# Configure the servcie endpoint

AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$serviceEndpointSpPassword
az devops service-endpoint azurerm create --azure-rm-service-principal-id $serviceEndpointSpAppId --azure-rm-subscription-id $serviceEndpointSubscriptionId --azure-rm-subscription-name $serviceEndpointSubscriptionName --azure-rm-tenant-id $serviceEndpointSpTenant --name ${projectName}Se
