<#
    Version    : 1.0
    File Name  : Install-Panda.ps1  
    Author     : @kieranwalsh
    Date       : 2017-02-02
#>

$PandaShare = '\\Server\Panda$\WAAgent.msi'
$logPath = 'C:\TEMP\Panda'
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

