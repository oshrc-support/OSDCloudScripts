az account set --subscription 4dc12530-2664-4d5a-853b-c32a1c90b2da

az group create --name oshrc-prod-osdcloud-rg --location eastus

az deployment group create --resource-group oshrc-prod-osdcloud-rg --template-file "C:\Repos\OSDCloudScripts\Azure Function\deployment.bicep"