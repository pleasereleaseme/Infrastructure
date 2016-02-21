#
# Demonstrates creating multiple VMs via a standard Foreach loop
#

# Authentication details are abstracted away in a PS module
Set-AzureRmAuthenticationForMsdnEnterprise

$resourceGroupName = 'PRM-DQA'
New-AzureRmResourceGroup -Name $resourceGroupName -Location westeurope -Force

# DQA environments need one VM for SQL Server and one for IIS
$vmsToCreate = "$resourceGroupName-SQL", "$resourceGroupName-IIS"

Foreach ($vm in $vmsToCreate) {

	New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
                                   -TemplateFile "$PSScriptRoot\..\DeploymentTemplates\WindowsServer2012R2Datacenter.json" `
                                   -Force `
								   -Verbose `
								   -Mode Incremental `
								   -TemplateParameterObject @{
									   nodeName = $vm;
									   vmSize = 'Standard_DS1'
								   }
}