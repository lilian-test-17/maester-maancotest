# Requires -Module Pester

Describe "Find-StaleGuestUsers" -Tag "Custom", "Users" {
    BeforeAll {
        . "$PSScriptRoot\Find-StaleGuestUsers.ps1"
    }

    It "CUS.004: Should return guests who haven't accepted invitation and are older than expiration threshold" {

    try {
            $policies = Get-MgIdentityConditionalAccessPolicy -All

            $disabledWithoutReason = $policies | Where-Object { $_.State -eq "Disabled" -and $_.DisplayName -notlike "*Disabled:*" }

            $testDescription = "Checks if the disabled policies have the reason for being disabled."
            if ($disabledWithoutReason.Count -gt 0) {
                $result = "There are $($disabledWithoutReason.Count) disabled policies without a reason for being disabled."
                Add-MtTestResultDetail -Description $testDescription -Result $result
            } else {
                Add-MtTestResultDetail -Description $testDescription -Result "Well done. All disabled policies have a reason for being disabled."
            }
        } catch {
            Write-Error $_.Exception.Message
        }

        $disabledWithoutReason | Should -Be 0

        $fakeDate = (Get-Date).AddDays(-31)

        Mock -CommandName Get-MgUser -MockWith {
            return @(
                [pscustomobject]@{
                    DisplayName = "User A"
                    UserPrincipalName = "usera@example.com"
                    ExternalUserState = "PendingAcceptance"
                    CreatedDateTime = $fakeDate
                },
                [pscustomobject]@{
                    DisplayName = "User B"
                    UserPrincipalName = "userb@example.com"
                    ExternalUserState = "Accepted"
                    CreatedDateTime = $fakeDate
                },
                [pscustomobject]@{
                    DisplayName = "User C"
                    UserPrincipalName = "userc@example.com"
                    ExternalUserState = "PendingAcceptance"
                    CreatedDateTime = (Get-Date) # trop récent
                }
            )
        }

        $result = Find-StaleGuestUsers -ExpirationDays 30

        $result | Should -HaveCount 1
        $result[0].UserPrincipalName | Should -Be "usera@example.com"
    }
}
