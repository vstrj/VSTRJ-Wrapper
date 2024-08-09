# VSTRJ-Wrapper
<#
.SYNOPSIS
  A clean Wrapping script with a few built in functions
.DESCRIPTION
  A clean Wrapping script with a few built in functions. Such as Write-ScriptLog for log writing, Set-RegKey for writing reg-keys, and Set-DetectionKey to write a detection method.
  Put your script in the main script region and utilize the built in functions as needed.
  Detection registry value, $ScriptName with data: $ScriotVersion under HKLM:\Software\$CompanyName
.PARAMETER ScriptName
    Returns the name of the script file and sets it as a variable
.PARAMETER ScriptVersion
    Sets the version of the script. Will be used in the registry for detection
.PARAMETER CompanyName
    Sets the company name that will be used both as folder for the log and the registry key for detection
.PARAMETER LogFolder
    Sets the folder will be created. By default a sub folder in C:\Program Data\ with the company name
.PARAMETER LogFolder
    Switch parameter to run the script in Remove mode
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
.NOTES
  Version:        1.0
  Author:         victor.storsjo@crayon.com
  Creation Date:  YYYY/MM/DD
  Purpose/Change: Initial script development
  
.EXAMPLE
  powershell.exe -ExecutionPolicy Bypass -file Set-StandardVictor.ps1 
  %windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -file Invoke-ChangeDefaultLanguage.ps1

  Set-StandardVictor.ps1 -Remove
#>
