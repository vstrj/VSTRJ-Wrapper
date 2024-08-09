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
.PARAMETER Remove
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
  powershell.exe -ExecutionPolicy Bypass -file verb-noun.ps1
  %windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -file verb-noun.ps1

  verb-noun.ps1 -Remove
#>

[CmdletBinding()]
param(
  [parameter(Mandatory = $false, HelpMessage = "Sets the script name")]
  [ValidateNotNullOrEmpty()]
  [string]$ScriptName = $MyInvocation.MyCommand.Name,

  [parameter(Mandatory = $false, HelpMessage = "Sets the script version")]
  [ValidateNotNullOrEmpty()]
  [string]$ScriptVersion = "1.0.0",

  [parameter(Mandatory = $false, HelpMessage = "Sets the company name for detection in registry and log folder")]
  [ValidateNotNullOrEmpty()]
  [string]$CompanyName = "VSTRJ",

  [parameter(Mandatory = $false, HelpMessage = "Sets the path where the log will be located")]
  [ValidateNotNullOrEmpty()]
  [string]$LogFolder = (Join-Path "$($env:ProgramData)" $CompanyName),

  [Parameter(ValueFromPipeline)]
  [Switch] $Remove
)
####################################################################################
#                             Here be Functions
####################################################################################

#region Functions

#Log function
function Write-ScriptLog {
  <#
  .SYNOPSIS
      Writes a log for the script.
  .DESCRIPTION
      Creates a logfile under the specified path with the default name $ScriptName. 
      If the directory does not exist, it creates it. 
      Information level can be Information, Warning, or ERROR.
  .PARAMETER Message
      The message that should be appended to the log.
  .PARAMETER Level
      Information level can be Information, Warning, or ERROR.
  .PARAMETER Path
      The path where the log should be created.            
  .NOTES
  Version:        1.0
  Author:         victor.storsjo@crayon.com
  Creation Date:  2024/08/07
  Purpose/Change: Initial script development
  Other info:     Some bits improved by ChatGPT 
  
  .EXAMPLE
  Write-ScriptLog -Message "Information Text" -Level Information
  Write-ScriptLog -Message "Warning Text" -Level Warning
  Write-ScriptLog -Message "Error Text" -Level Error
  #>

  [CmdletBinding()]
  param(
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Message,

      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [ValidateSet("Error","Warning","Information")]
      [string]$Level = "Information",

      [Parameter(Mandatory=$false)]
      [Alias('LogPath')]
      [string]$Path = (Join-path "$LogFolder" "$ScriptName.log")
  )

  Begin {
      $directory = [System.IO.Path]::GetDirectoryName($Path)
      if (-not (Test-Path $directory)) {
          New-Item -Path $directory -ItemType Directory | Out-Null
      }
        
      # Set VerbosePreference to Continue so that verbose messages are displayed.
      $VerbosePreference = 'Continue'
  }

  Process {
      $formattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
      # Write message to error, warning, or verbose pipeline and specify $LevelText
      switch ($Level) {
          'Error' {
              Write-Error $Message
              $levelText = 'ERROR:'
          }
          'Warning' {
              Write-Warning $Message
              $levelText = 'WARNING:'
          }
          'Information' {
              Write-Verbose $Message
              $levelText = 'INFORMATION:'
          }
      }
      # Write log entry to $Path
      "$formattedDate $levelText $Message" | Out-File -FilePath $Path -Append
  }
}
#Registry Function
function Set-RegKey {
    <#
    .SYNOPSIS
        Writes or removes a Registry Key Value and data.
    .DESCRIPTION
        Creates a Registry Key under the specified path with a Registry Value and data. 
        If the Registry Key does not exist, it creates it. If the Remove switch is used,
        it removes the specified Registry Value but not the key.
        Default detection registry value, $ScriptName with data: $ScriptVersion under HKLM:\Software\$CompanyName
        
    .PARAMETER RegKey
        The registry key that should be created or modified.
    .PARAMETER RegValue
        The registry value that should be created or removed.
    .PARAMETER RegData
        The data that should be in the registry value.
    .PARAMETER RegType
        The type of the registry value.
    .PARAMETER Remove
        Switch to indicate that the registry value should be removed.
    .NOTES
    Version:        1.2
    Author:         victor.storsjo@crayon.com
    Creation Date:  2024/08/07
    Purpose/Change: Initial script development, improved by ChatGPT
    
    .EXAMPLE
    Set-RegKey -RegKey "HKLM:\SOFTWARE\VSTRJ" -RegValue "vstrj_value" -RegData "00000001" -RegType "DWord"
    Set-RegKey -RegKey "HKLM:\SOFTWARE\VSTRJ" -RegValue "vstrj_value" -Remove
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $RegKey,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $RegValue,

        [Parameter(Mandatory = $false)]
        [String] $RegData,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("String", "ExpandString", "Binary", "DWord", "MultiString", "Qword")]
        [String] $RegType = "DWord",

        [Parameter(Mandatory = $false)]
        [Switch] $Remove
    )
  
    process {
        try {
            # Ensure the registry key exists
            if (-not (Test-Path $RegKey)) {
                if (-not $Remove) {
                    New-Item -Path $RegKey -Force | Out-Null
                    Write-ScriptLog -Message "Registry key $RegKey created!"
                } else {
                    Write-ScriptLog -Message "Registry key does not exist, cannot remove value." -Level Error
                    return
                }
            }

            if ($Remove) {
                # Remove the specified registry value
                if ($null -ne (Get-ItemProperty -Path $RegKey -Name $RegValue -ErrorAction SilentlyContinue)) {
                    Remove-ItemProperty -Path $RegKey -Name $RegValue -Force
                    Write-ScriptLog -Message "Removed $RegValue value from registry"
                } else {
                    Write-ScriptLog -Message "$RegValue does not exist"
                }
            } else {
                # Set the registry value
                New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType $RegType -Force | Out-Null
                Write-ScriptLog "Created value $RegValue value in registry with $RegData"
            }
        }
        catch {
            Write-ScriptLog "Could not change $RegValue value in registry: $_"
                        
        }
    }
}

# Detection Function

function Set-DetectionKey {
    <#
    .SYNOPSIS
        Creates or removes a detection value in the registry.
    .DESCRIPTION
        Creates a Registry Key under the specified path with a Registry Value and data.
        Can then be used for detection methods in for example; Intune, SCCM.
        If the Registry Key does not exist, it creates it. If the Remove switch is used,
        it removes the specified Registry Value but not the key.
        
    .PARAMETER DetectKey
        The registry key that should be created or modified.
    .PARAMETER DetectValue
        The script name that will go in the registry value that should be created or removed.
    .PARAMETER DetectVersion
        The script version that should be in the registry value.
    .PARAMETER Remove
        Switch to indicate that the registry value should be removed.
    .NOTES
    Version:        1.2
    Author:         victor.storsjo@crayon.com
    Creation Date:  2024/08/07
    Purpose/Change: Initial script development, improved by ChatGPT
    
    .EXAMPLE
    Set-DetectionKey
    Set-DetectionKey -DetectKey "HKLM:\SOFTWARE\VSTRJ" -DetectValue "Scriptname.ps1" -DetectVersion "1.0.0"
    Set-DetectionKey -Remove -DetectKey "HKLM:\SOFTWARE\VSTRJ" -DetectValue "Scriptname.ps1"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String] $DetectKey = "HKLM:\SOFTWARE\$CompanyName",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String] $DetectValue = $ScriptName ,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String] $DetectVersion = $ScriptVersion,

        [Parameter(Mandatory = $false)]
        [Switch] $Remove
    )

    Begin {
        if (-not (Test-Path $DetectKey)) {
            if (-not $Remove) {
                New-Item -Path $DetectKey -Force | Out-Null
                Write-ScriptLog -Message "Registry key $DetectKey created!"
            } else {
                Write-Host "Registry key does not exist, cannot remove value."
                return
            }
        }
    }

    Process {
        if (-not $Remove) {
            Write-ScriptLog -Message "Setting Detection value" 
            Set-RegKey -RegKey $DetectKey -RegValue $DetectValue -RegData $DetectVersion -RegType "String"
        } else {
            Set-RegKey -RegKey $DetectKey -RegValue $DetectValue -Remove
        }
    }
}

#endregion Functions

####################################################################################
#                             Here be Main Script
####################################################################################
#region Main Script

if (-not $Remove){
    Write-ScriptLog -Message "Starting Running $ScriptName version $ScriptVersion" -Level Information
#----------------------------Script stuff goes below here!----------------------------------


#----------------------------Script stuff goes above here!----------------------------------
#Detection default; $ScriptName with data: $ScriotVersion under HKLM:\Software\$CompanyName
Set-DetectionKey
}


#endregion Main Script

####################################################################################
#                             Here be Remove Section
####################################################################################
#regtion Switch Remove

if ($Remove){
  

    Set-DetectionKey -Remove
}

#endregion Switch Remove

####################################################################################
#                             Here be Exit Code
####################################################################################
#region Exit Code

<#
Exit Codes 
0 = Success
1707 = Success
3010 = Soft Reboot
1641 = Hard Reboot
1618 = Retry

#>

Exit 0

#endregion  Exit Code
