# Requires -Module Pester

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

            if ($guests.Count -gt 0) {
                $result = "❌ Found $($guests.Count) guest(s) pending for more than $expirationDays days."
                Add-MtTestResultDetail -Description $testDescription -Result $result

                # Pester : le test échoue
                $guests.Count | Should -Be 0
            } else {
                $result = "✅ No stale guest users found. All guests accepted or are within the allowed timeframe."
                Add-MtTestResultDetail -Description $testDescription -Result $result

                # Pester : le test passe
                $true | Should -Be $true
            }

        } catch {
            $msg = "❌ Error: $($_.Exception.Message)"
            Add-MtTestResultDetail -Description "Error while checking guest invitations" -Result $msg
            Throw $_
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
