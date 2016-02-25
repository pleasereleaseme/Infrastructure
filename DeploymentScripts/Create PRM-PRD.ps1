#
# Demonstrates creating multiple VMs via a Foreach loop using the -parallel switch
# This code currently not working!!!! See https://disqus.com/home/discussion/thewindowsazureproductsite/deploy_an_application_with_azure_resource_manager_template/#comment-2522268046
#

workflow Create-WindowsServer2012R2Datacenter
{
	param ([string[]] $vms, [string] $resourceGroupName, [string] $solutionRoot)

	Foreach -parallel($vm in $vms)

	{
		# Authentication details are abstracted away in a PS module
		Set-AzureRmAuthenticationForMsdnEnterprise
		
		New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
									   -TemplateFile "$solutionRoot\..\DeploymentTemplates\WindowsServer2012R2Datacenter.json" `
									   -Force `
									   -Verbose `
									   -Mode Incremental `
									   -TemplateParameterObject @{
										   nodeName = $vm;
										   vmSize = 'Standard_DS1';
										   vmAdminPassword = 'MySuperSecurePassword'
									   }

	}
}

$resourceGroupName = 'PRM-PRD'

New-AzureRmResourceGroup -Name $resourceGroupName -Location westeurope -Force

$virtualmachines = "$resourceGroupName-SQL", "$resourceGroupName-IIS"

Create-WindowsServer2012R2Datacenter -vms $virtualmachines -resourceGroupName $resourceGroupName -solutionRoot $PSScriptRoot