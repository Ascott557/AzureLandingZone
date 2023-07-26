#Deploy Infrastructure
$infratemplate = "$PSScriptRoot/infra/templates/ALZ/neu-resourcegroup-main.bicep"
$infraparameters = "{\""location\"": {\""value\"": \""$location\""}, `
                \""environment\"": {\""value\"": \""$environment\""}}"
$infrarg = "infra-rg-01"
az group create --location $location --name $infrarg                
az deployment group create --name $deploymentname --resource-group $infrarg --template-file $infratemplate --parameters $infraparameters
         
#Deploy AKS Environment
$envrg = "$application-$environment-rg-01"
$rgtemplate = "$PSScriptRoot/template/$application.json"
$parameters = "{\""location\"": {\""value\"": \""$location\""}, `
                \""application\"": {\""value\"": \""$application\""}, `
                \""environment\"": {\""value\"": \""$environment\""}, `
                \""servicePrincipalId\"": {\""value\"": \""$env:servicePrincipalId\""}}"

az group create --location $location --name $envrg                
az deployment group create --name $deploymentname --resource-group $envrg --template-file $rgtemplate --parameters $parameters
# Login-AzAccount -Tenant "412604e9-c2ed-4fda-8c9b-9cd9b394efa1"
# set-AzContext -subscription "a1bae54a-c004-46ad-ab91-0da318f283fe"         
Login-AzAccount -Tenant "85b0f265-7672-406a-aab9-b7338acbe280"
Connect-AzAccount -Tenant 85b0f265-7672-406a-aab9-b7338acbe280
$deploymentname = (Get-Date).ToString("yyyyMMddHHmmssfff") 
write-host "[Deploy] Resource Groups"
New-AzResourceGroup -Name 'rg-nethub-prd-neu-01' -Location 'northeurope' -Tag $tags -Force
New-AzResourceGroup -Name 'rg-netspk-prd-neu-01' -Location 'northeurope' -Tag $tags -Force
New-AzResourceGroup -Name 'rg-nethub-prd-weu-01' -Location 'westeurope' -Tag $tags -Force
New-AzResourceGroup -Name 'rg-netspk-prd-weu-01' -Location 'westeurope' -Tag $tags -Force
New-AzResourceGroup -Name 'rg-mgmt-prd-neu-01' -Location 'northeurope' -Tag $tags -Force
New-AzResourceGroup -Name 'rg-mgmt-prd-weu-01' -Location 'westeurope' -Tag $tags -Force
New-AzResourceGroup -Name 'rg-epma-prd-neu-01' -Location 'northeurope' -Tag $tags -Force
New-AzResourceGroup -Name 'rg-epma-prd-weu-01' -Location 'westeurope' -Tag $tags -Force
# New-AzDeployment -Name "$deploymentname-rg" -Location "northeurope" -TemplateFile "C:\Users\mail\OneDrive\source\Codec\Irish Life\infra\templates\ALZ\neu-resourcegroup-main.bicep"
# write-host "[Deploy] Management" 
#New-AzDeployment -Name "$deploymentname-mgmt2" -Location "northeurope" -TemplateFile "C:\Users\mail\OneDrive\source\Codec\Irish Life\infra\templates\ALZ\neu-management.bicep"
write-host "[Deploy] Networking"
New-AzDeployment -Name "$deploymentname-net" -Location "northeurope" -TemplateFile "C:\Users\mail\OneDrive\source\Codec\Irish Life\infra\templates\ALZ\neu-connectivity.bicep"
#$deploymentname = (Get-Date).ToString("yyyyMMddHHmmssfff") 
write-host "[Deploy] EPM Automate"

New-AzDeployment -Name "$deploymentname-rg" -Location "northeurope" -TemplateFile .\infra\templates\ALZ\neu-sharedresources.bicep -templateparameterfile .\infra\templates\alz\main.parameters.json  
