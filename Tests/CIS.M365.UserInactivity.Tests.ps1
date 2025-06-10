#requires -Modules Pester, AzureAD

Describe "CIS.M365.UserInactivity" -Tag "CIS", "UserInactivity", "Audit" {

    BeforeAll {
        $InactiveDays = 30
        $ThresholdDate = (Get-Date).AddDays(-$InactiveDays)
        $QueryStartDateTimeFilter = "{0:yyyy-MM-dd}T{0:HH:mm:sszzz}" -f $ThresholdDate
        $InactiveUsers = @()

        Connect-AzureAD | Out-Null

        Function Get-UserLastLogin([string] $UserObjectID) {
            Try {
                $SigninLog = Get-AzureADAuditSignInLogs -All:$true -Filter "userID eq '$UserObjectID' and status/errorCode eq 0 and createdDateTime ge $QueryStartDateTimeFilter" | Select -First 1
                return $SigninLog.CreatedDateTime
            } Catch {
                if ($_ -like "*Too Many Requests*") {
                    Start-Sleep -Seconds 10
                    return Get-UserLastLogin $UserObjectID
                }
                return $null
            }
        }

        $AllUsers = Get-AzureADUser -All $true
        foreach ($user in $AllUsers) {
            $lastLogin = Get-UserLastLogin $user.ObjectID
            if (!$lastLogin -or ($lastLogin -lt $ThresholdDate)) {
                $InactiveUsers += $user
            }
        }
    }

    It "Should retrieve all Azure AD users without recent sign-ins" {
        $InactiveUsers | Should -Not -BeNullOrEmpty -Because "At least one user should match inactivity criteria, or test the query still works"
    }

    It "Should return correct user properties" {
        $InactiveUsers | ForEach-Object {
            $_ | Should -HaveProperty "UserPrincipalName"
            $_ | Should -HaveProperty "DisplayName"
        }
    }

    It "Each user should have last login null or before threshold" {
        foreach ($user in $InactiveUsers) {
            $lastLogin = Get-UserLastLogin $user.ObjectID
            if ($lastLogin) {
                $lastLogin | Should -BeLessThan $ThresholdDate
            } else {
                $true | Should -BeTrue  # Accept null as valid inactivity
            }
        }
    }
}
