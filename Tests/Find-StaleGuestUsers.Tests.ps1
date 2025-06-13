Describe "Find-StaleGuestUsers" -Tag "Custom", "Users" {
    BeforeAll {
        . "$PSScriptRoot\Find-StaleGuestUsers.ps1"
    }

    It "CUS.004: Should return guests who haven't accepted invitation and are older than expiration threshold" {
        try {
            $expirationDays = 30
            $cutoffDate = (Get-Date).AddDays(-$expirationDays)

            # Appelle la fonction réelle ou simule-la dans un autre fichier
            $guests = Get-MgUser -Filter "userType eq 'Guest'" -All |
                Where-Object {
                    $_.ExternalUserState -ne "Accepted" -and
                    $_.CreatedDateTime -lt $cutoffDate
                }

            $testDescription = "Checks if there are stale guest users (pending > $expirationDays days)."
            $guests.Count | Should -Be 0
            Write-Host "DEBUG: Nombre d'invités stale = $($guests.Count)"

            if ($guests.Count -eq 0) {
                $result = "✅ No stale guest users found. All guests accepted or are within the allowed timeframe."
                Add-MtTestResultDetail -Description $testDescription -Result $result

                # Le test passe ici
                $true | Should -Be $true
            } else {
                $result = "❌ Found $($guests.Count) guest(s) pending for more than $expirationDays days."
                Add-MtTestResultDetail -Description $testDescription -Result $result

                # Le test échoue ici
                $guests.Count | Should -Be 0
            }

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
            $result[0].UserPrincipalName | Should -Be "usera@example.com" -Because "Because User A is the only one who hasn't accepted the invitation and is older than the expiration threshold"
        } catch {
            $msg = "❌ Error: $($_.Exception.Message)"
            Add-MtTestResultDetail -Description "Error while checking guest invitations" -Result $msg
            Throw $_
        }
    }
}
