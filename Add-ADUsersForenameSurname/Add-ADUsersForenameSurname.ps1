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
        $couldNotFind += $user.Username
    }
}

'Script complete.'
If($couldNotFind)
{
    ' '
    'The following users were not found in Active Directory:'
    $couldNotFind
}