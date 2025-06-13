Describe "Find-StaleGuestUsers" -Tag "Custom", "Users" {
    BeforeAll {
        # Assurez-vous que ce fichier contient la fonction Find-StaleGuestUsers si tu l'utilises
        . "$PSScriptRoot\Find-StaleGuestUsers.ps1"
    }

    It "CUS.004: Should fail if guests haven't accepted invitation and are older than expiration threshold" {
        $expirationDays = 30
        $cutoffDate = (Get-Date).AddDays(-$expirationDays)

        try {
            # Requête réelle à l'API Microsoft Graph
            $pendingGuests = Get-MgUser -Filter "userType eq 'Guest'" -All |
                Where-Object {
                    $_.ExternalUserState -ne "Accepted" -and
                    $_.CreatedDateTime -lt $cutoffDate
                }

            $testDescription = "Checks for stale guest users (invited > $expirationDays days ago and still pending)"

            if ($pendingGuests.Count -gt 0) {
                $list = $pendingGuests | ForEach-Object {
                    "- $($_.DisplayName) <$($_.UserPrincipalName)> -"
                } | Out-String

                $result = "❌ Found $($pendingGuests.Count) stale guest(s):`n$list"
                Add-MtTestResultDetail -Description $testDescription -Result $result

                $false | Should -Be $true  # Force l’échec
            } else {
                Add-MtTestResultDetail -Description $testDescription -Result "✅ No stale guest users found."
                $true | Should -Be $true
            }
        } catch {
            $msg = "❌ Error: $($_.Exception.Message)"
            Add-MtTestResultDetail -Description "Error while checking guest invitations" -Result $msg
            throw $_
        }
    }
}
#Created: $($_.CreatedDateTime.ToString("yyyy-MM-dd"))"
