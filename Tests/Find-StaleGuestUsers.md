# Find-StaleGuestUsers

Ce test vérifie que les utilisateurs invités n'ayant pas accepté leur invitation dans un délai spécifié (par défaut 30 jours) sont bien identifiés.

## Comportement attendu

- Seuls les invités dont l’état `ExternalUserState` est différent de "Accepted"
- Et dont la date de création est antérieure à la date limite calculée (aujourd’hui - $ExpirationDays)

## Ce que teste ce script

- La fonction `Find-StaleGuestUsers` renvoie uniquement les utilisateurs correspondants à ces critères.
- `Get-MgUser` est mocké pour ne pas faire appel à l’API Microsoft Graph réelle.
