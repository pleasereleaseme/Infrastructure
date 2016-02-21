#
# Demonstrates creating single VM
#

# Authentication details are abstracted away in a PS module
Set-AzureRmAuthenticationForMsdnEnterprise

$resourceGroupName = 'PRM-DAT'

# Always need the resource group to be present
New-AzureRmResourceGroup -Name $resourceGroupName -Location westeurope -Force

# Deploy the contents of the template
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
                                   -TemplateFile "$PSScriptRoot\..\DeploymentTemplates\WindowsServer2012R2Datacenter.json" `
                                   -Force `
								   -Verbose `
								   -Mode Incremental `
								   -TemplateParameterObject @{
									   nodeName = "$resourceGroupName-AIO";
									   vmSize = 'Standard_DS1'
								   }