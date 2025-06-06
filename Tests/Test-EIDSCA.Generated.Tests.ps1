BeforeDiscovery {
$AuthorizationPolicyAvailable = (Invoke-MtGraphRequest -RelativeUri 'policies/authorizationpolicy' -ApiVersion beta)
$SettingsApiAvailable = (Invoke-MtGraphRequest -RelativeUri 'settings' -ApiVersion beta).values.name
$EntraIDPlan = Get-MtLicenseInformation -Product 'EntraID'
$EnabledAuthMethods = (Get-MtAuthenticationMethodPolicyConfig -State Enabled).Id
$EnabledAdminConsentWorkflow = (Invoke-MtGraphRequest -RelativeUri 'policies/adminConsentRequestPolicy' -ApiVersion beta).isenabled
}

Describe "EIDSCA" -Tag "EIDSCA", "Security", "All", "EIDSCA.AF01" {
    It "EIDSCA.AF01: Authentication Method - FIDO2 security key - State. See https://maester.dev/docs/tests/EIDSCA.AF01" {
        <#
            Check if "https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy/authenticationMethodConfigurations('Fido2')"
            .state -eq 'enabled'
        #>
        Test-MtEidscaControl -CheckId AF01 | Should -Be 'enabled'
    }
}
