
#!/bin/bash

usage() { echo "Usage: provision_devops.sh -o <organization> -p <projectName> -r <repositoryName> -t <templateGitHubProject> -u <userEmails> -a <acrName> " 1>&2; exit 1; }

declare organization="" 
declare projectName=""
declare repositoryName=""
declare templateGitHubProject=""
declare userEmails=""
declare acrName=""

# Initialize parameters specified from command line
while getopts ":o:p:r:t:u:a:" arg; do
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
echo "=========================================="


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

# Fetch the data of ACR

cred=$(az acr credential show -n $acrName)
acrUsername=$(echo $cred | jq .username | xargs )
acrPassword=$(echo $cred | jq .passwords[0].value | xargs )
conf=$(az acr show -n $acrName)
acrLoginServer=$(echo $conf | jq .loginServer | xargs )

# Configure the variables of ACR

az pipelines variable create --name registryUrl --value $acrLoginServer --pipeline-name eShopOnWeb-Docker.CI -p $projectName
az pipelines variable create --name registryPassword --value $acrPassword --pipeline-name eShopOnWeb-Docker.CI -p $projectName
az pipelines variable create --name registryName --value $acrUsername --pipeline-name eShopOnWeb-Docker.CI -p $projectName


