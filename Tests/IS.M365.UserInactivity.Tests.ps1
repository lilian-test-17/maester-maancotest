# Nom du fichier : CIS.M365.UserInactivity.Tests.ps1

Describe "CIS User Inactivity Tests" -Tag "CIS.M365.UserInactivity", "L1", "CIS E3 Level 1", "CIS E3", "CIS", "Security", "All", "CIS M365 v5.0.0" {
    It "CIS.M365.UserInactivity: (L1) Ensure users inactive for 30 days are identified" {

        # Calculer la date il y a 30 jours
        $inactiveSinceDate = (Get-Date).AddDays(-30)

        # Récupérer tous les utilisateurs
        $users = Get-AzureADUser -All $true

        # Filtrer les utilisateurs qui ne se sont pas connectés depuis 30 jours
        $inactiveUsers = $users | Where-Object {
            $_.LastDirSyncTime -lt $inactiveSinceDate -or $_.LastDirSyncTime -eq $null
        }

        # Vérifier si des utilisateurs inactifs ont été trouvés
        $result = $inactiveUsers.Count -gt 0

        if ($null -ne $result) {
            $result | Should -Be $true -Because "There are users who have not signed in for 30 days"
        }
    }
}
