az group create --name oshrc-prod-osdcloud-rg --location eastus

az deployment group create --resource-group oshrc-prod-osdcloud-rg --template-file deployment.bicep