###NOTE: This test module requires use of credentials. The first run through of the tests will prompt for credentials from the logged on user.

Import-Module $PSScriptRoot\..\DSCResources\MSFT_xExchActiveSyncVirtualDirectory\MSFT_xExchActiveSyncVirtualDirectory.psm1
Import-Module $PSScriptRoot\..\Misc\xExchangeCommon.psm1 -Verbose:0
Import-Module $PSScriptRoot\xExchange.Tests.Common.psm1 -Verbose:0

#Check if Exchange is installed on this machine. If not, we can't run tests
[bool]$exchangeInstalled = IsSetupComplete

if ($exchangeInstalled)
{
    #Get required credentials to use for the test
    if ($null -eq $Global:ShellCredentials)
    {
        [PSCredential]$Global:ShellCredentials = Get-Credential -Message "Enter credentials for connecting a Remote PowerShell session to Exchange"
    }

    #Get the Server FQDN for using in URL's
    if ($null -eq $Global:ServerFqdn)
    {
        $Global:ServerFqdn = [System.Net.Dns]::GetHostByName($env:COMPUTERNAME).HostName
    }

    if ($null -eq $Global:WebCertAuthInstalled)
    {
        $webCertAuth = Get-WindowsFeature -Name Web-Cert-Auth

        if ($webCertAuth.InstallState -ne "Installed")
        {
            $Global:WebCertAuthInstalled = $false
            Write-Verbose "Web-Cert-Auth is not installed. Skipping certificate based authentication tests."
        }
        else
        {
            $Global:WebCertAuthInstalled = $true
        }

    }

    if ($Global:WebCertAuthInstalled -eq $true)
    {
        #Get the thumbprint to use for ActiveSync Cert Based Auth
        if ($null -eq $Global:CBACertThumbprint)
        {
            $Global:CBACertThumbprint = Read-Host -Prompt "Enter the thumbprint of an Exchange certificate to use when enabling Certificate Based Authentication"
        }
    }

    Describe "Test Setting Properties with xExchActiveSyncVirtualDirectory" {
        $testParams = @{
            Identity =  "$($env:COMPUTERNAME)\Microsoft-Server-ActiveSync (Default Web Site)"
            Credential = $Global:ShellCredentials
            AutoCertBasedAuth = $false
            AutoCertBasedAuthThumbprint = ''
            BadItemReportingEnabled = $false
            BasicAuthEnabled = $true
            ClientCertAuth = 'Ignore'
            CompressionEnabled = $true
            ExtendedProtectionFlags = @("AllowDotlessSPN","NoServicenameCheck")
            ExtendedProtectionSPNList = @("http/mail.fabrikam.com","http/mail.fabrikam.local","http/wxweqc")
            ExtendedProtectionTokenChecking = "Allow"
            ExternalAuthenticationMethods = @("Basic","Kerberos")
            ExternalUrl = "https://$($Global:ServerFqdn)/Microsoft-Server-ActiveSync"
            InstallIsapiFilter = $true
            InternalAuthenticationMethods = @("Basic","Kerberos")
            InternalUrl = "https://$($Global:ServerFqdn)/Microsoft-Server-ActiveSync"
            MobileClientCertificateAuthorityURL = "http://whatever.com/CA"
            MobileClientCertificateProvisioningEnabled = $true
            MobileClientCertTemplateName = "MyTemplateforEAS"
            #Name = "$($Node.NodeName) EAS Site"
            RemoteDocumentsActionForUnknownServers = "Block"
            RemoteDocumentsAllowedServers = @("AllowedA","AllowedB")
            RemoteDocumentsBlockedServers = @("BlockedA","BlockedB")
            RemoteDocumentsInternalDomainSuffixList = @("InternalA","InternalB")
            SendWatsonReport = $false
            WindowsAuthEnabled = $false
        }

        $expectedGetResults = @{
            Identity =  "$($env:COMPUTERNAME)\Microsoft-Server-ActiveSync (Default Web Site)"
            BadItemReportingEnabled = $false
            BasicAuthEnabled = $true
            ClientCertAuth = 'Ignore'
            CompressionEnabled = $true
            ExtendedProtectionTokenChecking = "Allow"
            ExternalUrl = "https://$($Global:ServerFqdn)/Microsoft-Server-ActiveSync"
            InternalAuthenticationMethods = @("Basic","Kerberos")
            InternalUrl = "https://$($Global:ServerFqdn)/Microsoft-Server-ActiveSync"
            MobileClientCertificateAuthorityURL = "http://whatever.com/CA"
            MobileClientCertificateProvisioningEnabled = $true
            MobileClientCertTemplateName = "MyTemplateforEAS"
            #Name = "$($Node.NodeName) EAS Site"
            RemoteDocumentsActionForUnknownServers = "Block"
            SendWatsonReport = $false
            WindowsAuthEnabled = $false 
        }

        Test-TargetResourceFunctionality -Params $testParams -ContextLabel "Set standard parameters" -ExpectedGetResults $expectedGetResults
        Test-ArrayContentsEqual -TestParams $testParams -DesiredArrayContents $testParams.ExtendedProtectionFlags -GetResultParameterName "ExtendedProtectionFlags" -ContextLabel "Verify ExtendedProtectionFlags" -ItLabel "ExtendedProtectionSPNList should contain three values"
        Test-ArrayContentsEqual -TestParams $testParams -DesiredArrayContents $testParams.ExtendedProtectionSPNList -GetResultParameterName "ExtendedProtectionSPNList" -ContextLabel "Verify ExtendedProtectionSPNList" -ItLabel "ExtendedProtectionSPNList should contain three values"
        Test-ArrayContentsEqual -TestParams $testParams -DesiredArrayContents $testParams.ExternalAuthenticationMethods -GetResultParameterName "ExternalAuthenticationMethods" -ContextLabel "Verify ExternalAuthenticationMethods" -ItLabel "ExternalAuthenticationMethods should contain two values"
        Test-ArrayContentsEqual -TestParams $testParams -DesiredArrayContents $testParams.InternalAuthenticationMethods -GetResultParameterName "InternalAuthenticationMethods" -ContextLabel "Verify InternalAuthenticationMethods" -ItLabel "InternalAuthenticationMethods should contain two values"
        Test-ArrayContentsEqual -TestParams $testParams -DesiredArrayContents $testParams.ExtendedProtectionFlags -GetResultParameterName "ExtendedProtectionFlags" -ContextLabel "Verify ExtendedProtectionFlags" -ItLabel "ExtendedProtectionFlags should contain two values"
        Test-ArrayContentsEqual -TestParams $testParams -DesiredArrayContents $testParams.RemoteDocumentsAllowedServers -GetResultParameterName "RemoteDocumentsAllowedServers" -ContextLabel "Verify RemoteDocumentsAllowedServers" -ItLabel "RemoteDocumentsAllowedServers should contain two values"
        Test-ArrayContentsEqual -TestParams $testParams -DesiredArrayContents $testParams.RemoteDocumentsBlockedServers -GetResultParameterName "RemoteDocumentsBlockedServers" -ContextLabel "Verify RemoteDocumentsBlockedServers" -ItLabel "RemoteDocumentsBlockedServers should contain two values"
        Test-ArrayContentsEqual -TestParams $testParams -DesiredArrayContents $testParams.RemoteDocumentsInternalDomainSuffixList -GetResultParameterName "RemoteDocumentsInternalDomainSuffixList" -ContextLabel "Verify RemoteDocumentsInternalDomainSuffixList" -ItLabel "RemoteDocumentsInternalDomainSuffixList should contain two values"



        $testParams.ExternalUrl = ''
        $testParams.InternalUrl = ''
        $expectedGetResults.ExternalUrl = $null
        $expectedGetResults.InternalUrl = $null

        Test-TargetResourceFunctionality -Params $testParams -ContextLabel "Try with empty URL's" -ExpectedGetResults $expectedGetResults


        if ($Global:WebCertAuthInstalled -eq $true)
        {
            $testParams.AutoCertBasedAuth = $true
            $testParams.AutoCertBasedAuthThumbprint = $Global:CBACertThumbprint
            $testParams.ClientCertAuth = 'Required'
            $expectedGetResults.ClientCertAuth = 'Required'

            Test-TargetResourceFunctionality -Params $testParams -ContextLabel "Try enabling certificate based authentication" -ExpectedGetResults $expectedGetResults
        }

        Context "Test missing ExtendedProtectionFlags for ExtendedProtectionSPNList" {
            $caughtException = $false
            $testParams.ExtendedProtectionFlags = @("NoServicenameCheck")
            try
            {
                $SetResults = Set-TargetResource @testParams
            }
            catch
            {
                $caughtException = $true
            }

            It "Should hit exception for missing ExtendedProtectionFlags AllowDotlessSPN" {
                $caughtException | Should Be $true
            }

            It "Test results should be true after adding missing ExtendedProtectionFlags" {
                $testParams.ExtendedProtectionFlags = @("AllowDotlessSPN")
                Set-TargetResource @testParams
                $testResults = Test-TargetResource @testParams
                $testResults | Should Be $true
            }
        }

        $testParams.ActiveSyncServer = "https://eas.$($env:USERDNSDOMAIN)/Microsoft-Server-ActiveSync"
        $testParams.Remove("ExternalUrl")
        $expectedGetResults.ActiveSyncServer = "https://eas.$($env:USERDNSDOMAIN)/Microsoft-Server-ActiveSync"
        $expectedGetResults.ExternalUrl = "https://eas.$($env:USERDNSDOMAIN)/Microsoft-Server-ActiveSync"

        Test-TargetResourceFunctionality -Params $testParams -ContextLabel "Try by setting External URL via ActiveSyncServer" -ExpectedGetResults $expectedGetResults

        #Set values back to default
        $testParams = @{
            Identity =  "$($env:COMPUTERNAME)\Microsoft-Server-ActiveSync (Default Web Site)"
            Credential = $Global:ShellCredentials
            BadItemReportingEnabled = $true
            BasicAuthEnabled = $false
            ClientCertAuth = 'Ignore'
            CompressionEnabled = $false
            ExtendedProtectionFlags = $null
            ExtendedProtectionSPNList = $null
            ExtendedProtectionTokenChecking = 'None'
            ExternalAuthenticationMethods = $null
            InternalAuthenticationMethods = $null
            MobileClientCertificateAuthorityURL = $null
            MobileClientCertificateProvisioningEnabled = $false
            MobileClientCertTemplateName = $null
            RemoteDocumentsActionForUnknownServers = 'Allow'
            RemoteDocumentsAllowedServers = $null
            RemoteDocumentsBlockedServers = $null
            RemoteDocumentsInternalDomainSuffixList = $null
            SendWatsonReport = $true
            WindowsAuthEnabled = $true
        }

        $expectedGetResults = @{
            Identity =  "$($env:COMPUTERNAME)\Microsoft-Server-ActiveSync (Default Web Site)"
            BadItemReportingEnabled = $true
            BasicAuthEnabled = $false
            ClientCertAuth = 'Ignore'
            CompressionEnabled = $false
            ExtendedProtectionFlags = $null
            ExtendedProtectionSPNList = $null
            ExtendedProtectionTokenChecking = 'None'
            ExternalAuthenticationMethods = $null
            InternalAuthenticationMethods = $null
            MobileClientCertificateAuthorityURL = ''
            MobileClientCertificateProvisioningEnabled = $false
            MobileClientCertTemplateName = ''
            RemoteDocumentsActionForUnknownServers = 'Allow'
            RemoteDocumentsAllowedServers = $null
            RemoteDocumentsBlockedServers = $null
            RemoteDocumentsInternalDomainSuffixList = $null
            SendWatsonReport = $true
            WindowsAuthEnabled = $true
        }

        Test-TargetResourceFunctionality -Params $testParams -ContextLabel "Reset values to default" -ExpectedGetResults $expectedGetResults
    }
}
else
{
    Write-Verbose "Tests in this file require that Exchange is installed to be run."
}

