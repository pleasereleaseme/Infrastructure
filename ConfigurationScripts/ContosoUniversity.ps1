CLS
Remove-Item C:\Dsc\Mof\*

# Authentication details are abstracted away in a PS module
Set-AzureRmAuthenticationForMsdnEnterprise

$vaultname = 'prmkeyvault'
$domainAdminPassword = Get-AzureKeyVaultSecret –VaultName $vaultname –Name DomainAdminPassword
$SecurePassword = ConvertTo-SecureString -String $domainAdminPassword.SecretValueText -AsPlainText -Force
$domainAdministratorCredential = New-Object System.Management.Automation.PSCredential ("PRM\graham", $SecurePassword)

$appPoolDomainAccountPassword = Get-AzureKeyVaultSecret –VaultName $vaultname –Name AppPoolDomainAccountPassword
$SecurePassword = ConvertTo-SecureString -String $appPoolDomainAccountPassword.SecretValueText -AsPlainText -Force
$appPoolDomainAccountCredential = New-Object System.Management.Automation.PSCredential ("PRM\CU-DAT", $SecurePassword)

$configurationData = 
@{
    AllNodes = 
    @(
        @{
            NodeName = 'PRM-DAT-AIO'
            Roles = @('Web', 'Database')
            AppPoolUserName = 'PRM\CU-DAT'
            AppPoolCredential = $appPoolDomainAccountCredential
            PSDscAllowDomainUser = $true
            PSDscAllowPlainTextPassword = $true
            DomainAdministratorCredential = $domainAdministratorCredential
        }		
    )
}

Configuration WebAndDatabase
{
    Import-DscResource –ModuleName PSDesiredStateConfiguration
    Import-DscResource –ModuleName @{ModuleName="cWebAdministration";ModuleVersion="2.0.1"}
    Import-DscResource -ModuleName @{ModuleName="xWebAdministration";ModuleVersion="1.10.0.0"}
    Import-DscResource -ModuleName  @{ModuleName="xSQLServer";ModuleVersion="1.5.0.0"}

    Node $AllNodes.Where({$_.Roles -contains 'Web'}).NodeName
    {
        # Configure for web server role
        WindowsFeature DotNet45Core
        {
            Ensure = 'Present'
            Name = 'NET-Framework-45-Core'
        }
        WindowsFeature IIS
        {
            Ensure = 'Present'
            Name = 'Web-Server'
        }
         WindowsFeature AspNet45
        {
            Ensure = "Present"
            Name = "Web-Asp-Net45"
        }

        # Configure ContosoUniversity
        File ContosoUniversity
        {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = "C:\inetpub\ContosoUniversity"
        }
        xWebAppPool ContosoUniversity
        {
            Ensure = "Present"
            Name = "ContosoUniversity"
            State = "Started"
            DependsOn = "[WindowsFeature]IIS"
        }
        cAppPool ContosoUniversity
        {
            Name = "ContosoUniversity"
            IdentityType = "SpecificUser"
            UserName = $Node.AppPoolUserName
            Password = $Node.AppPoolCredential
            DependsOn = "[xWebAppPool]ContosoUniversity"
        }
        xWebsite ContosoUniversity
        {
            Ensure = "Present"
            Name = "ContosoUniversity"
            State = "Started"
            PhysicalPath = "C:\inetpub\ContosoUniversity"
            BindingInfo = MSFT_xWebBindingInformation
            {
                Protocol = 'http'
                Port = '80'
                HostName = $Node.NodeName
                IPAddress = '*'
            }
            ApplicationPool = "ContosoUniversity"
            DependsOn = "[cAppPool]ContosoUniversity"
        }

        # Configure for development mode only
        WindowsFeature IISTools
        {
            Ensure = "Present"
            Name = "Web-Mgmt-Tools"
        }

        # Clean up the uneeded website and application pools
        xWebsite Default
        {
            Ensure = "Absent"
            Name = "Default Web Site"
        }
        xWebAppPool NETv45
        {
            Ensure = "Absent"
            Name = ".NET v4.5"
        }
        xWebAppPool NETv45Classic
        {
            Ensure = "Absent"
            Name = ".NET v4.5 Classic"
        }
        xWebAppPool Default
        {
            Ensure = "Absent"
            Name = "DefaultAppPool"
        }
        File wwwroot
        {
            Ensure = "Absent"
            Type = "Directory"
            DestinationPath = "C:\inetpub\wwwroot"
            Force = $True
        }
    }

    Node $AllNodes.Where({$_.Roles -contains 'Database'}).NodeName
    {
        WindowsFeature "NETFrameworkCore"
        {
            Ensure = "Present"
            Name = "NET-Framework-Core"
        }
        xSqlServerSetup "SQLServerEngine"
        {
            DependsOn = "[WindowsFeature]NETFrameworkCore"
            SourcePath = "\\prm-core-dc\DscInstallationMedia"
            SourceFolder = "SqlServer2014"
            SetupCredential = $Node.DomainAdministratorCredential
            InstanceName = "MSSQLSERVER"
            Features = "SQLENGINE"
        }

        # Configure for development mode only
        xSqlServerSetup "SQLServerManagementTools"
        {
            DependsOn = "[WindowsFeature]NETFrameworkCore"
            SourcePath = "\\prm-core-dc\DscInstallationMedia"
            SourceFolder = "SqlServer2014"
            SetupCredential = $Node.DomainAdministratorCredential
            InstanceName = "NULL"
            Features = "SSMS,ADV_SSMS"
        }
    }
}
WebAndDatabase -ConfigurationData $configurationData -OutputPath C:\Dsc\Mof -Verbose

[DscLocalConfigurationManager()]
Configuration LocalConfigurationManager
{

    Node $AllNodes.NodeName
    {
        Settings
        {
            RefreshMode = 'Push'
            AllowModuleOverwrite = $True
            # A configuration Id needs to be specified, known bug
            ConfigurationID = '3a15d863-bd25-432c-9e45-9199afecde91'
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $True   
        }

        ResourceRepositoryShare FileShare
        {
            SourcePath = '\\prm-core-dc\DscResources\'
        }
    }
}
LocalConfigurationManager -ConfigurationData $configurationData -OutputPath C:\Dsc\Mof -Verbose

Set-DscLocalConfigurationManager -Path C:\Dsc\Mof -Verbose
Start-DSCConfiguration -Path C:\Dsc\Mof -Wait -Verbose -Force