# Requires -Module Pester

Describe "Find-StaleGuestUsers" {
    BeforeAll {
        . "$PSScriptRoot\Find-StaleGuestUsers.ps1"
    }

    It "should return guests who haven't accepted invitation and are older than expiration threshold" {
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
