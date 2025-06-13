Describe "Find-StaleGuestUsers" -Tag "Custom", "Users" {
    BeforeAll {
        . "$PSScriptRoot\Find-StaleGuestUsers.ps1"
    }

    Context "Test réel (sans mock)" {
        It "CUS.004: Should return guests pending for more than expiration threshold" {
            try {
                $expirationDays = 30
                $cutoffDate = (Get-Date).AddDays(-$expirationDays)

                $guests = Get-MgUser -Filter "userType eq 'Guest'" -All |
                    Where-Object {
                        $_.ExternalUserState -ne "Accepted" -and
                        $_.CreatedDateTime -lt $cutoffDate
                    }

                $testDescription = "Checks if there are stale guest users (pending > $expirationDays days)."

                if ($guests.Count -gt 0) {
                    Add-MtTestResultDetail -Description $testDescription -Result "❌ Found $($guests.Count) guest(s) pending for more than $expirationDays days."
                    $guests.Count | Should -Be 0
                } else {
                    Add-MtTestResultDetail -Description $testDescription -Result "✅ No stale guest users found."
                    $true | Should -Be $true
                }
            } catch {
                Add-MtTestResultDetail -Description "Error while checking guest invitations" -Result "❌ Error: $($_.Exception.Message)"
                Throw $_
            }
        }
    }

    Context "Test avec mock" {
        It "CUS.005: Should return guests who haven't accepted invitation and are older than expiration threshold (mocked)" {
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

            # Appelle ta fonction qui doit utiliser Get-MgUser
            $result = Find-StaleGuestUsers -ExpirationDays 30

            $result | Should -HaveCount 1
            $result[0].UserPrincipalName | Should -Be "usera@example.com"
        }
    }
}
