## This is a list of the scripts included here plus a short description.

- **Get-FreePCs** - This will list any PCs on the domain that do not have any logged on users so you can remote into it for testing.
- **Add-ADUsersForenameSurname** - This script will read a list of usernames, forenames, and surnames from a CSV file and adds those to existing AD user accounts. If the script can't find any of the users in AD those are listed at the completion of the script.
- **Install-Panda** - This is to be used as a startup script to install the Panada Cloud agent. It also fixes the problem of semi-installed Panda Agents that can occur if oyu deploy the MSI via GPO.