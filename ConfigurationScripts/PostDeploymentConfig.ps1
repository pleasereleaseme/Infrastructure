Configuration PostDeploymentConfig
{
    Node localhost
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        Script TurnOffDomainFireWall
        {
            SetScript = 
            { 
                Set-NetFirewallProfile -Profile Domain -Enabled False
            }
            TestScript = { $false }
            GetScript = { @{ Result = "" } }
        }
    }
}