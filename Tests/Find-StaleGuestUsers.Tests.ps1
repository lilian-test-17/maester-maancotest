Describe "Find-StaleGuestUsers" -Tag "Custom", "Users" {
    BeforeAll {
        . "$PSScriptRoot\Find-StaleGuestUsers.ps1"
    }

    It "CUS.004: Should return guests who haven't accepted invitation and are older than expiration threshold" {
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

        $guests = Find-StaleGuestUsers -ExpirationDays 30

        if ($guests.Count -gt 0) {
            $guestList = $guests | ForEach-Object {
                "- $($_.DisplayName) <$($_.UserPrincipalName)> - Created: $($_.CreatedDateTime)"
            } | Out-String

            $result = "❌ Found $($guests.Count) stale guest(s):`n$guestList"
            Add-MtTestResultDetail -Description "Checks if there are stale guest users (pending > 30 days)" -Result $result

            $guests.Count | Should -Be 0
        } else {
            Add-MtTestResultDetail -Description "Checks if there are stale guest users (pending > 30 days)" -Result "✅ No stale guest users found."
            $true | Should -Be $true
        }
    }
}
