
#!/bin/bash

usage() { echo "Usage: provision_devops.sh -u <userEmails> -t <teamNumber> -s '<personalAccessToken>'" 1>&2; exit 1; }

declare organization="https://dev.azure.com/DevSecOpsOH"
declare repositoryName="eShopOnWeb"
declare templateGitHubProject="https://github.com/rguthriemsft/eShopOnWeb"
declare userEmails=""
declare acrConfigFile="acr.json"
declare subscriptionConfigFile="subscription.json"

# Initialize parameters specified from command line
while getopts ":u:t:s:" arg; do
    case "${arg}" in

        u)
            userEmails=${OPTARG}
        ;;
        t)
            teamNumber=${OPTARG}
        ;;
        s)
            personalAccessToken=${OPTARG}
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
echo "teamNumber                = "${teamNumber}
echo "=========================================="

# Fetch the data of ACR. This section assume acr,json was created in previous step
conf=$(cat ${acrConfigFile})
acrUsername=$(echo $conf | jq .acrUserName | xargs )
acrPassword=$(echo $conf | jq .acrPassword | xargs )
acrLoginServer=$(echo $conf | jq .acrLoginServer | xargs )

# Read in SP information
sp_conf=$(cat ${subscriptionConfigFile})
serviceEndpointSpAppId=$(echo $sp_conf | jq .appId | xargs )
serviceEndpointSpPassword=$(echo $sp_conf | jq .password | xargs )
serviceEndpointSpTenant=$(echo $sp_conf | jq .tenant | xargs )
serviceEndpointSubscriptionId=$(echo $sp_conf | jq .subscriptionId | xargs )
serviceEndpointSubscriptionName=$(echo $sp_conf | jq .subscriptionName | xargs )
storageConnectionString=$(echo $sp_conf | jq .storageConnectionString | xargs )

# Check and add extension
az extension add --name azure-devops
az devops configure --defaults organization=$organization

# Create Project
az devops project create --name $projectName --organization $organization -p Agile

# Add users to Administrator groups
CurrentIFS=$IFS
IFS=','
read -r -a emails <<< "$userEmails"
echo "userEmails: ${userEmails}"

for email in "${emails[@]}"
do
  echo "email: ${email}"
  az devops user add --email-id $email --license-type stakeholder --organization $organization --send-email-invite false
  projectAdministratorDescriptor=`az devops security group list --organization $organization -p $projectName --scope=project --query "graphGroups[?displayName=='Project Administrators'].descriptor" --output tsv`
  buildAdministratorDescriptor=`az devops security group list --organization $organization -p $projectName --scope=project --query "graphGroups[?displayName=='Build Administrators'].descriptor" --output tsv`
  teamDescriptor=`az devops security group list --organization $organization -p $projectName --scope=project --query "graphGroups[?displayName=='$projectName Team'].descriptor" --output tsv`
  memberDescriptor=`az devops user show --user $email --query 'user.descriptor' --output tsv`
  az devops security group membership add --group-id $projectAdministratorDescriptor --member-id $memberDescriptor --organization $organization
  az devops security group membership add --group-id $buildAdministratorDescriptor --member-id $memberDescriptor --organization $organization
  az devops security group membership add --group-id $teamDescriptor --member-id $memberDescriptor --organization $organization
done

IFS=$CurrentIFS

# Prepare Git repo
git config --global core.autocrlf false
git config --global core.eol lf
git clone --mirror $templateGitHubProject $repositoryName/.git
cd $repositoryName
git config --bool core.bare false
git checkout master
sed -i "s/REPLACEWITHCS/${storageConnectionString}/g" src/Infrastructure/Data/StorageAcctDbSeed.cs
git commit -a -m "Updated connection string."
git checkout ch1_Fix
git merge master
perl -i -0pe 's/(<<<<<<< HEAD\n)//gm' src/Infrastructure/Data/StorageAcctDbSeed.cs
perl -i -0pe 's/(=======)([\S\s]*?)(>>>>>>> master\n)//mg' src/Infrastructure/Data/StorageAcctDbSeed.cs
git commit -a -m "Resolved merge conflict."
git checkout master
repoUrl=$(az repos create -p $projectName --name $repositoryName --organization $organization --query 'remoteUrl' -o tsv)
repoUrl=$(sed "s/@/:${personalAccessToken}@/g" <<<$repoUrl)
git push --mirror $repoUrl
cd ..
rm -rf $repositoryName

# Create Two Pipelines with configuring variables and service connection
az pipelines create --name 'eShopOnWeb.CI' --description 'Pipeline for building eShopWeb on Windows' --repository $repositoryName --branch master --repository-type tfsgit --yaml-path eShopOnWeb-CI.yml -p $projectName --skip-run --organization $organization
az pipelines create --name 'eShopOnWeb-Docker.CI' --description 'Pipeline for building eShopWeb on Windows' --repository $repositoryName --branch master --repository-type tfsgit --yaml-path eShopOnWeb-Docker-CI.yml -p $projectName --skip-run --organization $organization

# Configure the variables of ACR
az pipelines variable create --name registryUrl --value $acrLoginServer --pipeline-name eShopOnWeb-Docker.CI -p $projectName --organization $organization
az pipelines variable create --name registryPassword --value $acrPassword --pipeline-name eShopOnWeb-Docker.CI -p $projectName --organization $organization
az pipelines variable create --name registryName --value $acrUsername --pipeline-name eShopOnWeb-Docker.CI -p $projectName --organization $organization

# Configure the servcie endpoint
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$serviceEndpointSpPassword
az devops service-endpoint azurerm create --azure-rm-service-principal-id $serviceEndpointSpAppId --azure-rm-subscription-id $serviceEndpointSubscriptionId --azure-rm-subscription-name "${serviceEndpointSubscriptionName}" --azure-rm-tenant-id $serviceEndpointSpTenant --name ${projectName}Se --project ${projectName} --organization $organization

# Delete the default repo
REPO_ID=`az repos list --organization $organization -p $projectName --query "[?name=='$projectName']" | jq '.[0].id' | tr -d '"'`

echo "Deleting repo $projectName with ID: $REPO_ID"

az repos delete --id $REPO_ID --organization $organization -p $projectName --yes

# Append to subscription.json
projectId=$(az devops project show -p $projectName --org $organization | jq .id)
projectIdTrimmed=$(echo "${projectId//\"}")

configeFileData=$(cat ${subscriptionConfigFile})
echo  $configeFileData |jq --arg ProjName ${projectName} --arg projId ${projectIdTrimmed} '. + {projectName: $ProjName, projectIdTrimmed: $projId}' | jq . > subscription.json
