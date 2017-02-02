<#
    Version    : 1.0
    File Name  : Add-ADUsersForenameSurname.ps1
    Author     : @kieranwalsh
    Date       : 2017-01-27
#>
 
 $users = Import-Csv -Path 'C:\SRV\AD Usernames.csv'
$couldNotFind = @()

foreach($user in $users)
{
    "Configuring $($user.username)"
    try
    {
        $null = Get-ADUser $user.username -ErrorAction Stop
        Set-ADUser -Identity $user.username -GivenName $user.Forename -Surname $user.Surname
    }
    catch
    {
        $couldNotFind= $user.Username
    }
}

'Script complete.'
If($couldNotFind)
{
    ' '
    'The following users were not found in Active Directory:'
    $couldNotFind
}