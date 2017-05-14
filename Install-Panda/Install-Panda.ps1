<#
        .SYNOPSIS
        This is a group policy startup script to install the Panda Cloud Agent from a network share.            
        .DESCRIPTION
        To use this script create a new group policy and add this to the PowerShell startup scripts section.
        You will need the Panada agent saved in a network location which you specify in the '$PandaShare' variable.
        There is no need to change the executionpolicy of machines as startup and shutdown scripts always run under 'bypass' mode.
        A basic log of start/stop times is saved in the logpath and file that you specify. This will allow you to check that it has run.
        .NOTES
        Version    : 1.0
        File Name  : Install-Panda.ps1
        Author     : @kieranwalsh
        Date       : 2017-02-02
        .EXAMPLE
        There are no examples as this script is not generally run from the host.

#>


$PandaShare = '\\Server\Panda$\WAAgent.msi'
$logPath = 'C:\Program Files\Computer Talk\Panda'
$logFile = 'Installation.log'

$AVStatus = Get-WmiObject -Namespace root\SecurityCenter2 -Class AntiVirusProduct -ErrorAction SilentlyContinue
If(-not($AVStatus))
{  
    $null = New-Item -Path $logPath -ItemType Directory -Force
    try
    {
        # No Antivirus detected - let's check if Panda is partially installed.
        $PandaLocations = @(
            'C:\Program Files\Panda Security\WaAgent\WAPWInst\WAPWInst.exe', 
            'C:\Program Files(x86)\Panda Security\WaAgent\WAPWInst\WAPWInst.exe'
        )
        $PandaLocations | ForEach-Object -Process {
            $LocalPandaFile += (Get-ChildItem -Path $_ -ErrorAction SilentlyContinue).fullname
        }
        Get-Item $LocalPandaFile -ErrorAction Stop
        # Panda is Partially installed.
        $startMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm')`tBeginning Panda fix."
        $File = $LocalPandaFile
        $Args = '-force'
        $endMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm')`tCompleted Panda installation fix."
    }
    catch
    {
        # New Panda installation required.
        $startMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm')`tBeginning Panda installation."
        $File = $PandaShare
        $Args = '/quiet /norestart'
        $endMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm')`tCompleted Panda installation."
    }
    finally
    {
        # Run install or fix with variables defined above.
        $startMessage|Out-File -FilePath $("$logPath\$logFile") -Force -Append
        Start-Process -FilePath $File -ArgumentList $Args
        $endMessage|Out-File -FilePath $("$logPath\$logFile") -Force -Append
    }
}

