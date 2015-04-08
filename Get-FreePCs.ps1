#version 2.00.00 Kieran Walsh April 2015

[CmdletBinding()]
Param(
    [Parameter(Position = 1)]
    [string]$Name = '',
    [switch]$Workstations,
    [switch]$AvailableOnly
)

# If missing, add pre-reqs of: AD DS Snap-Ins, Command-Line Tools and Active Directory module for Windows PowerShell
$prerequisites = ('RSAT-ADDS-Tools', 'RSAT-AD-PowerShell')
foreach($prerequisite in $prerequisites){If ((Get-WindowsFeature -name $prerequisite).Installed){}else{Add-WindowsFeature -Name $prerequisite}}

# Get list of required computers
Write-Verbose -Message 'Querying Active Directory for the list of computers.'
If ($Workstations -eq $true){$Computers = Get-ADComputer -properties Name -Filter {OperatingSystem -notLike '*Server*'}| Where-Object -FilterScript {$_.name -match $Name}}
ELSE
{$Computers = Get-ADComputer -properties Name | Where-Object -FilterScript {$_.name -match $Name}}

# Get logged on users
Foreach ($Computer in $Computers){
    Write-Verbose -Message "Testing connection to $($Computer.name)"
    If(Test-Connection -ComputerName $Computer.name -Count 1 -Quiet){
        $User = @(Get-WmiObject -ComputerName $Computer -Namespace root\cimv2 -Class Win32_ComputerSystem)[0].UserName
        If ($AvailableOnly -eq $true -and $User -eq $null){
        $AvailableComputers += $Computer}
        Else
        {"$Computer"}
        
        if ($User -ne $null)
        {"$Computer"}
    }
    Else
    {
        If ($AvailableOnly -eq $true)
        {}
        Else
        {"$Computer Off"}
    }
}

# Output required list