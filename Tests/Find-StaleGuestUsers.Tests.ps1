Describe "Find-StaleGuestUsers" -Tag "Custom", "Users" {
    BeforeAll {
        . "$PSScriptRoot\Find-StaleGuestUsers.ps1"
    }

    It "CUS.004: Should return guests who haven't accepted invitation and are older than expiration threshold" {
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
                $guestList = $guests | ForEach-Object {
                    "- $($_.DisplayName) <$($_.UserPrincipalName)> - Created: $($_.CreatedDateTime)"
                } | Out-String

                $result = "❌ Found $($guests.Count) stale guest(s):`n$guestList"
                Add-MtTestResultDetail -Description $testDescription -Result $result

                $guests.Count | Should -Be 0  # Le test échouera ici si des guests existent
            } else {
                Add-MtTestResultDetail -Description $testDescription -Result "✅ No stale guest users found."
                $true | Should -Be $true
            }

        } catch {
            $msg = "❌ Error: $($_.Exception.Message)"
            Add-MtTestResultDetail -Description "Error while checking guest invitations" -Result $msg
            Throw $_
        }
    }
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
        $result[0].UserPrincipalName | Should -Be "usera@example.com" -Because "Parce que"
    }
}
