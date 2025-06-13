# Documentation : Mettre en place l'outil Maester

## Étape 0 (À faire une fois uniquement)

Fork le REPO suivant : https://github.com/lilian-17/maester-action
C'est le repertoire qu'on appellera lors du teste

## Étape 1 :

Fork le REPO suivant : https://github.com/lilian-17/maester-contoso puis remplacer contoso par le nom du client
Il faut un répertoire par client

## Étape 2 : 

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
