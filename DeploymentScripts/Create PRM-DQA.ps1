#
# Demonstrates creating multiple VMs via a standard Foreach loop
#

# Authentication details are abstracted away in a PS module
Set-AzureRmAuthenticationForMsdnEnterprise

$vaultname = 'prmkeyvault'
$vmAdminPassword = Get-AzureKeyVaultSecret –VaultName $vaultname –Name VmAdminPassword
$domainAdminPassword = Get-AzureKeyVaultSecret –VaultName $vaultname –Name DomainAdminAdminPassword

$resourceGroupName = 'PRM-DQA'

# Always need the resource group to be present
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
									   vmSize = 'Standard_DS4';
									   vmAdminPassword = $vmAdminPassword.SecretValueText;
									   domainAdminPassword = $domainAdminPassword.SecretValueText
								   }
}