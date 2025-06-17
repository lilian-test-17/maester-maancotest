 # Mettre en place l'outil Maester

## Étape 0 (À faire une fois uniquement)

Fork (ou importer) le répertoire  suivant : https://github.com/lilian-17/maester-action
C'est le repertoire qu'on appellera lors du teste

## Étape 1 : FORK

Fork le REPO suivant : https://github.com/lilian-17/maester-contoso puis remplacer contoso par le nom du client
Il faut un répertoire par client

Puis a la ligne 26 du fichier .github/workflows/main.yml remplacer "lilian-17" par le username de votre compte GitHub

## Étape 2 : Configuration de l'application

Aller sur la page ENTRA de votre client : 
Puis dans : 
    Applications -> App Registration -> New Registration

### Création de l'app :


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

Toujours sur l'application crée 
-> Certifacetes & Secrets
-> Federated Credentials -> Add Credential
-> Pour Federated credential scenario choisisser GitHub Actions deploying Azure resources
Puis remplisser les différents champs :
- Organization : Username GitHub
- Repository: Le REPO GitHub créer précédemment
- Entity Type : Branch
- GitHub branch name : main
- Credential Details -> Name : Ce que vous voulez

## Étape 3 : Ajouts des infos du tenant au repo GitHub


Ouvrer le repo GitHub et aller dans les settings
Security -> Secrets and variables -> Actions
Cliquer sur New Repository Secret
Puis créer 2 variable au nom de :
- AZURE_TENANT_ID -> The Directory (tenant) ID of the Entra tenant
- AZURE_CLIENT_ID -> The Application (client) ID of the Entra application you created
Puis Add Secret

---

Pour Tester si ca fonctionne ->
Sur le repertoire, aller dans l'onglet Action -> Run Maester 🔥 -> Run Workflow

---

## Étape 4 : Configuration alerte mail

### Créer l'utilisateur qui enverra les mails 

Créer un utilisateur qui permettra d'envoyer les resultats par mail, et de lui attribué une licence
Noté son ID d'objet et insérer le ligne 40 de .github/workflows/main.yml

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

