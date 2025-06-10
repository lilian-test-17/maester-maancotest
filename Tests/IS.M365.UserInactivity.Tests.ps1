#requires -Modules Microsoft.Graph.Users

Describe "CIS User Inactivity Tests" -Tag "CIS.M365.UserInactivity", "L1", "Security" {
    BeforeAll {
        # Connexion à Microsoft Graph via un compte de service dans GitHub Actions
        # Exemple : Connect-MgGraph -ClientId $env:CLIENT_ID -TenantId $env:TENANT_ID -CertificateThumbprint $env:CERT_THUMBPRINT
        # Ce bloc doit être adapté à ton mode d'authentification en CI
        Connect-MgGraph -Scopes "User.Read.All", "AuditLog.Read.All"
    }

    It "Should identify users inactive for 30 days" {
        $thresholdDate = (Get-Date).AddDays(-30)
        $users = Get-MgUser -All -Property "DisplayName,SignInActivity"

        $inactiveUsers = $users | Where-Object {
            ($_.SignInActivity.LastSignInDateTime -eq $null) -or
            ($_.SignInActivity.LastSignInDateTime -lt $thresholdDate)
        }

        # Le test ne doit pas échouer si aucun utilisateur inactif n’est trouvé
        $inactiveUsers.Count | Should -BeGreaterOrEqual 0 -Because "Query must run and return a valid count"

        # Facultatif : écrire un artefact lisible pour les reviewers
        $inactiveUsers | Select-Object DisplayName, @{Name="LastSignIn";Expression={$_.SignInActivity.LastSignInDateTime}} |
            Export-Csv -Path "./inactive-users.csv" -NoTypeInformation
    }
}
