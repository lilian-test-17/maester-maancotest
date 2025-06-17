 # Mettre en place l'outil Maester

## Étape 0 (À faire une fois uniquement)

Forkez (ou importez) le répertoire suivant :
https://github.com/lilian-17/maester-action
C’est le répertoire qui sera appelé lors des tests.

## Étape 1 : FORK

Forkez le dépôt suivant :
https://github.com/lilian-17/maester-contoso
puis **remplacez contoso par le nom du client.**
Il faut un répertoire par client.

Ensuite, à la ligne 26 du fichier .github/workflows/main.yml, remplacez **"lilian-17"** par le nom d’utilisateur de votre compte GitHub.

## Étape 2 : Configuration de l'application

### Création de l'app :

Exécuter le script suivant pour créer l'application

```powershell
#Installation de Microsoft.Graph
Install-Module Microsoft.Graph -Scope CurrentUser

# Connexion (si ce n'est pas déjà fait)
Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Directory.ReadWrite.All"

# Paramètres
$appName = "Maester App"
$graphAppId = "00000003-0000-0000-c000-000000000000"       # Microsoft Graph
$exchangeAppId = "00000002-0000-0ff1-ce00-000000000000"    # Exchange Online

$graphPermissions = @(
    "DeviceManagementConfiguration.Read.All",
    "DeviceManagementManagedDevices.Read.All",
    "Directory.Read.All",
    "DirectoryRecommendations.Read.All",
    "IdentityRiskEvent.Read.All",
    "Policy.Read.All",
    "Policy.Read.ConditionalAccess",
    "PrivilegedAccess.Read.AzureAD",
    "Reports.Read.All",
    "RoleEligibilitySchedule.Read.Directory",
    "RoleEligibilitySchedule.ReadWrite.Directory",
    "RoleManagement.Read.All",
    "SharePointTenantSettings.Read.All",
    "UserAuthenticationMethod.Read.All"
)

$exchangePermissions = @("Exchange.ManageAsApp")

# Création de l'application
$app = New-MgApplication -DisplayName $appName -RequiredResourceAccess @()

# Création de l'enregistrement de l'application (service principal)
$sp = New-MgServicePrincipal -AppId $app.AppId

# Microsoft Graph : récupération du service principal
$graphSP = Get-MgServicePrincipal -Filter "AppId eq '$graphAppId'"
$graphRoles = $graphSP.AppRoles | Where-Object { $_.Value -in $graphPermissions }

# Attribution des rôles Microsoft Graph
foreach ($role in $graphRoles) {
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id `
        -PrincipalId $sp.Id `
        -ResourceId $graphSP.Id `
        -AppRoleId $role.Id
}

# Exchange Online : récupération du service principal
$exchangeSP = Get-MgServicePrincipal -Filter "AppId eq '$exchangeAppId'"
$exchangeRoles = $exchangeSP.AppRoles | Where-Object { $_.Value -in $exchangePermissions }

# Attribution des rôles Exchange Online
foreach ($role in $exchangeRoles) {
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id `
        -PrincipalId $sp.Id `
        -ResourceId $exchangeSP.Id `
        -AppRoleId $role.Id
}

# Résultat
Write-Host "`n✅ Application '$appName' créée avec toutes les permissions requises (Graph + Exchange)." -ForegroundColor Green
Write-Host "❗ N'oubliez pas d'effectuer le 'Grant admin consent' dans Azure Portal." -ForegroundColor Yellow
```

### Ajouts des secrets 
Toujours sur l’application créée :
→ Certificates & secrets
→ Federated credentials → Add credential
→ Pour le scénario Federated credential scenario, choisissez GitHub Actions deploying Azure resources

Puis remplissez les différents champs :

Organization : nom d’utilisateur GitHub

Repository : le dépôt GitHub créé précédemment

Entity Type : Branch

GitHub branch name : main

Credential details → Name : ce que vous voulez

## Étape 3 : Ajouts des infos du tenant au repo GitHub
Ouvrez le dépôt GitHub et allez dans Settings
→ Security → Secrets and variables → Actions
Cliquez sur New repository secret, puis créez deux secrets avec les noms suivants :

**AZURE_TENANT_ID** → l’ID du tenant (Directory ID) de votre tenant Entra

**AZURE_CLIENT_ID** → l’ID de l’application (client ID) que vous avez créée dans Entra

Puis cliquez sur Add secret.

---
Tester si tout fonctionne
Dans le dépôt GitHub, allez dans l’onglet Actions
→ Run Maester 🔥
→ Cliquez sur Run workflow

---

## Étape 4 : Configuration alerte mail

### Créer l'utilisateur qui enverra les mails 

Créez un utilisateur dédié à l’envoi des résultats par e-mail (par exemple via le portail Azure ou PowerShell).

Attribuez-lui une licence compatible avec l’envoi d’e-mails (Exchange Online par exemple).

Notez son ID d’objet (Object ID).

Insérez cet ID à la ligne 40 du fichier .github/workflows/main.yml.

#### Si vous n'avez pas le Module ExchangeOnlineManagement installer le :

```powershell
Install-Module ExchangeOnlineManagement
```

#### Si vous avez déja le module Exchange :

```powershell
Import-Module ExchangeOnlineManagement

# Authenticate to Entra and Exchange Online
Connect-MgGraph -Scopes 'Application.Read.All'
Connect-ExchangeOnline

#Remplacer 'Maester' par le nom de l'application que vous avez créer
$entraSP = Get-MgServicePrincipal -Filter "DisplayName eq 'Maester'"

New-ServicePrincipal -AppId $entraSP.AppId -ObjectId $entraSP.Id -DisplayName $entraSP.DisplayName

#Remplacer maesterdemo@contoso.microsoft.com par l'email de l'utilisateur que vous avez créer
$mailbox = Get-Mailbox maesterdemo@contoso.onmicrosoft.com

New-ManagementScope -Name "rbac_Maester" -RecipientRestrictionFilter "GUID -eq '$($mailbox.GUID)'"

New-ManagementRoleAssignment -App $entraSP.AppId -Role "Application Mail.Send" -CustomResourceScope "rbac_Maester" -Name "Maester Send Mail RBAC"

# Verify access. This should show a line with Mail.Send permission and InScope = True
Test-ServicePrincipalAuthorization $entraSP.AppId -Resource $mailbox

Write-Host "Use '$($mailbox.ExternalDirectoryObjectId)' when calling Invoke-Maester -MailUserId or Send-MtMail -UserId"
```

---

## Autres : 

Pour changer le moment d'execution du teste automatique il faut changer le cron a la ligne 10 du main.yml
Voici un schéma pour comprendre comment ca fonctionne :


┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of the month (1 - 31)
│ │ │ ┌───────────── month (1 - 12 or JAN-DEC)
│ │ │ │ ┌───────────── day of the week (0 - 6 or SUN-SAT)
│ │ │ │ │
│ │ │ │ │
│ │ │ │ │
* * * * *

