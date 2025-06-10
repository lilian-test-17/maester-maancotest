# Prérequis : Connect-MgGraph avec les scopes appropriés
$inactiveSince = (Get-Date).AddDays(-30).ToString("o")
$users = Get-MgUser -All -Property DisplayName,SignInActivity

$inactiveUsers = $users | Where-Object {
    $_.SignInActivity.LastSignInDateTime -lt $inactiveSince -or
    $_.SignInActivity.LastSignInDateTime -eq $null
}

$inactiveUsers | Format-Table DisplayName, @{Name="LastSignIn"; Expression={$_.SignInActivity.LastSignInDateTime}}
