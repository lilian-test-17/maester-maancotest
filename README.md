# Documentation : Mettre en place l'outil Maester

## Étape 0 (À faire une fois uniquement)

Fork le REPO suivant : https://github.com/lilian-17/maester-action
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

- Donner lui un nom (ex: Maester App)
- Ouvrer l'application que vous venez de créer
- Api Permissions -> Add a Permissions
- Microsoft Graph -> Applications Permissions
- Puis cocher les autorisations suivantes :
  - DeviceManagementConfiguration.Read.All
  - DeviceManagementManagedDevices.Read.All
  - Directory.Read.All
  - DirectoryRecommendations.Read.All
  - IdentityRiskEvent.Read.All
  - Policy.Read.All
  - Policy.Read.ConditionalAccess
  - PrivilegedAccess.Read.AzureAD
  - Reports.Read.All
  - RoleEligibilitySchedule.Read.Directory
  - RoleEligibilitySchedule.ReadWrite.Directory
  - RoleManagement.Read.All
  - SharePointTenantSettings.Read.All
  - UserAuthenticationMethod.Read.All
- Add permissions
- Grant admin consent for [le client
- Yes pour confirmer

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



