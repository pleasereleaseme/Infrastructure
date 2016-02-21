# Authentication details are abstracted away in a PS module
Set-AzureRmAuthenticationForMsdnEnterprise

# Deletes all resources in the resource group!!
Remove-AzureRmResourceGroup -Name PRM-DAT -Force