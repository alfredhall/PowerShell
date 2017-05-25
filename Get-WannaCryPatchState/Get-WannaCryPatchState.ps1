#this script was written by @KieranWalsh and obtained at https://github.com/kieranwalsh/PowerShell/blob/master/Get-WannaCryPatchState/Get-WannaCryPatchState.ps1
#modified by Alfred Hall to support multiple jobs for parallelism
#and output in csv format
#
#Version 1.08.00 @KieranWalsh May 2017
# Computer Talk LTD

# Thanks to https://github.com/TLaborde, and https://www.facebook.com/BlackV for notifying me about missing patches.
#
#
# Updated 5/22/2017 Alfred Hall to run parallel poweshell jobs to hopefully increase speed of script
# and output to csv format with these columns "MachineName, ConnectStatus, PatchStatus, Patch" 
#
#
# Update 5/25/2017 Alfred Hall to accept pipeline input of computer names to check
#                  if parameter is null, then it will obtain machine names from Active Directory
#                  this will block the pipeline and consume more memeory as it will read in the entire list of names
#                  
#



[CmdletBinding()]

Param(
          [Parameter(
              Mandatory=$False,
              ValueFromPipeline=$True,
              ValueFromPipelineByPropertyName=$True
          )][string[]]$inputComputer
     )









########################################################################################
Begin
{
    $inputComputers = @()

    $Patches = @('KB4012212', 'KB4012213', 'KB4012214', 'KB4012215', 'KB4012216', 'KB4012217', 'KB4012598', 'KB4013429', 'KB4015217', 'KB4015438', 'KB4015549', 'KB4015550', 'KB4015551', 'KB4015552', 'KB4015553', 'KB4016635', 'KB4019215', 'KB4019216', 'KB4019264', 'KB4019472')
    $outputDirectory = "C:\PatchCheck\Output\"
    $NumJobs = 20

    # uncomment to ask user for number of jobs to run
    #$NumJobs = Read-Host -Prompt 'How many jobs to spawn?'

    #$log = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath "WannaCry patch state for $($ENV:USERDOMAIN).log"
    $log = $outputDirectory + "wannacrypatchstate_" + $(Get-Date -format "yyyyMMddHHmmss") + ".log"
    
    $OffComputers = @()
    $CheckFail = @()
    $Patched = @()
    $Unpatched = @()


    #script block that will be run as a powershell job
    $sb = {
            param(
                    $Computers, #array of computers to check
                    $Patches,  #array of patch names to look for
                    $log  #log file for results
                );
        
            foreach($Computer in $Computers)
            {
              $ThisComputerPatches = @()

              try
              {
                $null = Test-Connection -ComputerName $Computer -Count 1 -ErrorAction Stop
                try
                {
                  $Hotfixes = Get-HotFix -ComputerName $Computer -ErrorAction Stop

                  $Patches | ForEach-Object -Process {
                    if($Hotfixes.HotFixID -contains $_)
                    {
                      $ThisComputerPatches += $_
                    }
                  }
                }
                catch
                {
                  $CheckFail += $Computer
                  #"***`t$Computer `tUnable to gather hotfix information" | Out-File -FilePath $log -Append
                  $Computer + "," + "Success" + "," + "Unable to gather hotfix information" + "," | Out-File -FilePath $log -Append
                  continue
                }
                If($ThisComputerPatches)
                {
                  #"$Computer is patched with $($ThisComputerPatches -join (','))" | Out-File -FilePath $log -Append
                  $Computer + "," + "Success" + "," + "Patched" + "," + $($ThisComputerPatches -join (',')) | Out-File -FilePath $log -Append
                  $Patched += $Computer
                }
                Else
                {
                  $Unpatched += $Computer
                  #"*****`t$Computer IS UNPATCHED! *****" | Out-File -FilePath $log -Append
                  $Computer + "," + "Success" + "," + "UnPatched" + "," | Out-File -FilePath $log -Append
                }
              }
              catch
              {
                $OffComputers += $Computer
                #"****`t$Computer `tUnable to connect." | Out-File -FilePath $log -Append
                $Computer + "," + "Failure" + "," + "Unknown" + "," | Out-File -FilePath $log -Append
              }
           }#endof foreach
    
        }#endof script block



}#endof Begin Block









########################################################################################
Process
{
    #fill up an array of all computer names from pipeline, this will block the pipeline and consume more memory
    $inputComputers += $inputComputer
}#endof Process Block












########################################################################################
End
{
    #if user passed in list of computers, then use that list, otherwise pull all computers from Active Directory
    if( $inputComputers.Count -eq 0  )
    {


        $WindowsComputers = (Get-ADComputer -Filter {
            (OperatingSystem  -Like 'Windows*') -and (OperatingSystem -notlike '*Windows 10*')
        }).Name|
        Sort-Object

    }
    else
    {
        $WindowsComputers = $inputComputers
    }

    


    "MachineName,ConnectStatus,PatchStatus,Patch" | Out-File -FilePath $log 


    $ComputerCount = $WindowsComputers.Count
    "There are $ComputerCount computers to check"

    $arraySize = [math]::ceiling($ComputerCount / $NumJobs)
    $ComputerBatches = New-Object System.Collections.ArrayList  


    for($i=0; $i -lt $ComputerCount; $i+=$arraySize)
    { 
        $tempArray =  $WindowsComputers[$i..($i+$arraySize-1)] 
        [void]$ComputerBatches.Add(  $tempArray )
    
    }




    #launch multiple jobs, which will all append to a common log file
    foreach( $batch in $ComputerBatches )
    {
        Start-Job -ScriptBlock $sb -ArgumentList $batch, $Patches, $log
    }



}#endof End Block
























<#
' '
"Summary for domain: $ENV:USERDNSDOMAIN"
"Unpatched ($($Unpatched.count)):" |Out-File -FilePath $log -Append
$Unpatched -join (', ')  |Out-File -FilePath $log -Append
'' |Out-File -FilePath $log -Append
"Patched ($($Patched.count)):" |Out-File -FilePath $log -Append
$Patched -join (', ') |Out-File -FilePath $log -Append
'' |Out-File -FilePath $log -Append
"Off/Untested($(($OffComputers + $CheckFail).count)):"|Out-File -FilePath $log -Append
($OffComputers + $CheckFail | Sort-Object)-join (', ')|Out-File -FilePath $log -Append

"Of the $($WindowsComputers.count) windows computers in active directory, $($OffComputers.count) were off, $($CheckFail.count) couldn't be checked, $($Unpatched.count) were unpatched and $($Patched.count) were successfully patched."
'Full details in the log file.'

try
{
  Start-Process -FilePath notepad++ -ArgumentList $log
}
catch
{
  Start-Process -FilePath notepad.exe -ArgumentList $log
}
#>

