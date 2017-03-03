function New-SQLLocalDBInstance
{
    <#
        .SYNOPSIS
            Creates a SQL Local DB Instance
        .DESCRIPTION
            Creates a SQL Local DB Instance
        .PARAMETER
        .EXAMPLE
        .NOTES
        .INPUTS
        .OUTPUTS
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $InstanceName
    )
    process
    {
        $Command = 'create {0}' -f $InstanceName
        Invoke-SQLLocalDBCommand -CommandParameters $Command
    }
}

function Remove-SQLLocalDBInstance
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $InstanceName
    )
    process
    {
        $Command = 'delete {0}' -f $InstanceName
        Invoke-SQLLocalDBCommand -CommandParameters $Command
    }
}

function Start-SQLLocalDBInstance
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $InstanceName
    )
    process
    {
        $Command = 'start {0}' -f $InstanceName
        Invoke-SQLLocalDBCommand -CommandParameters $Command
    }
}

function Stop-SQLLocalDBInstance
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $InstanceName,

        [Parameter(Position=1, Mandatory=$false, ParameterSetName='NOWAIT')]
        [Switch] $ShutdownNOWAIT,

        [Parameter(Position=2, Mandatory=$false, ParameterSetName='KILL')]
        [Switch] $ExternalKill
    )
    process
    {
        $Command = 'stop {0} ' -f $InstanceName

        if($ShutdownNOWAIT)
        {
            $Command += '-i'
        }
        elseif($ExternalKill)
        {
            $Command += '-k'
        }

        Invoke-SQLLocalDBCommand -CommandParameters $Command
    }
}

function Start-SQLLocalDBTraceAPI
{
    [CmdletBinding()]
    param
    (
    )
    process
    {
        $Command = 'trace on'
        Invoke-SQLLocalDBCommand -CommandParameters $Command
    }
}

function Stop-SQLLocalDBTraceAPI
{
    [CmdletBinding()]
    param
    (
    )
    process
    {
        $Command = 'trace off'
        Invoke-SQLLocalDBCommand -CommandParameters $Command
    }
}

function Get-SQLLocalDBInstance
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String[]] $InstanceName
    )
    process
    {

        if(-not $InstanceName)
        {
            [String[]] $InstanceName = @()
            $Command = 'info'

            $Results = Invoke-SQLLocalDBCommand -CommandParameters $Command
            $Lines = $Results -split "`n"
            $Lines |  ForEach-Object {
                if($_ -ne '')
                {
                    $InstanceName += $_
                }
            }
        }

        foreach($Instance in $InstanceName)
        {
            $Command = 'info "{0}"' -f $Instance
            $Results = Invoke-SQLLocalDBCommand -CommandParameters $Command
            $Lines = $Results -split "`n"
            $OutputObject = New-Object -TypeName PSObject; 
            $OutputObject.PSObject.TypeNames.Insert(0,'PoShSQLLocalDB.Instance')
            $Lines |  ForEach-Object { 
                if($_ -ne '')
                { 
                    $Prop = [regex]::Match($_,'^.*?(?=:)').Value
                    $Value = [regex]::Match($_,'(?<=\w:).+$').Value -replace '^ +' -replace '(?<=\w)\s+$'
                    $OutputObject | Add-Member -MemberType NoteProperty -Name $Prop -Value $Value  
                }
            }
            $OutputObject
        }
    }
}

function Get-SQLLocalDBVersions
{
    [CmdletBinding()]
    param
    (
    )
    process
    {
        $Command = 'versions'
        $Results = Invoke-SQLLocalDBCommand -CommandParameters $Command
        $Lines = $Results -split "`n"
        $Lines |  ForEach-Object { 
            if($_ -ne '')
            {   
                $OutputObject = New-Object -TypeName PSObject
                $OutputObject | Add-Member -MemberType NoteProperty -Name 'Version' -Value $_
                $OutputObject
            }
        }
    }
}

function Add-SQLLocalDBSharedInstance
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$true, ParameterSetName='ALL')]
        [ValidateNotNullOrEmpty()]
        [String] $InstanceName,

        [Parameter(Position=1, Mandatory=$true, ParameterSetName='ALL')]
        [ValidateNotNullOrEmpty()]
        [String] $SharedInstanceName,

        [Parameter(Position=2, Mandatory=$false, ParameterSetName='ALL')]
        [Parameter(Position=2, Mandatory=$false, ParameterSetName='SID')]
        [ValidateNotNullOrEmpty()]
        [String] $UserSID,

        [Parameter(Position=2, Mandatory=$false, ParameterSetName='ALL')]
        [Parameter(Position=2, Mandatory=$false, ParameterSetName='USER')]
        [ValidateNotNullOrEmpty()]
        [String] $UserAccount
    )
    process
    {
        $Command = 'share'

        if($UserSID)
        {
            $Command += (' "{0}"' -f $UserSID)
        }
        elseif($UserAccount)
        {
            $Command += (' "{0}"' -f $UserAccount)
        }
        else
        {
            $Command += ' ""'
        }
        
        $Command += ' "{0}" "{1}"' -f $InstanceName, $SharedInstanceName
        Invoke-SQLLocalDBCommand -CommandParameters $Command -RunAsAdministrator
        Write-Warning -Message ('You must restart the instance: "{0}" before sharing will take effect.' -f $InstanceName)
    }
}

function Remove-SQLLocalDBSharedInstanced
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $SharedInstanceName
    )
    process
    {
        $Command = 'unshare "{0}"' -f $SharedInstanceName
        Invoke-SQLLocalDBCommand -CommandParameters $Command -RunAsAdministrator
    }
}

<#
# Heavy Lifting
#>
function Invoke-SQLLocalDBCommand
{
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $CommandParameters,

        [Parameter(Position=0, Mandatory=$false)]
        [Switch] $RunAsAdministrator
    )
    begin
    {
        ##
        if($RunAsAdministrator)
        {
            $ErrorOutFile = '{0}\output\ErrorOut.log' -f $PSScriptRoot
            $StandardOutFile = '{0}\output\StandardOut.log' -f $PSScriptRoot
            $null = Remove-Item -Path $StandardOutFile -Force -ErrorAction SilentlyContinue
            $null = Remove-Item -Path $ErrorOutFile -Force -ErrorAction SilentlyContinue
        }
    }
    process
    {
        ## Build Process Start Information
        $ProcessInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo

        if($RunAsAdministrator)
        {
            $ProcessInfo.FileName = 'PowerShell.exe'
            $ProcessInfo.Verb = 'runas'
            $ProcessInfo.UseShellExecute = $true
            $ProcessInfo.WindowStyle = 'hidden'
            $ProcessInfo.CreateNoWindow = $true
            $CommandParameters = 'sqllocaldb.exe {0} 1> "{1}" 2> "{2}"' -f $CommandParameters, $StandardOutFile, $ErrorOutFile
            $ProcessInfo.Arguments = $CommandParameters
        }
        else
        {
            $ProcessInfo.FileName = 'SQLLocalDB.exe'
            $ProcessInfo.RedirectStandardError = $true
            $ProcessInfo.RedirectStandardOutput = $true
            $ProcessInfo.UseShellExecute = $false
            $ProcessInfo.Arguments = $CommandParameters
        }

        ## Build and Start Process
        $SQLLocalDBProcess = New-Object -TypeName System.Diagnostics.Process
        $SQLLocalDBProcess.StartInfo = $ProcessInfo
        $SQLLocalDBProcess.Start() | Out-Null

        if(-not $RunAsAdministrator)
        {
            ## Get Outputs
            $SQLLocalDBProcessStandardOut = $SQLLocalDBProcess.StandardOutput.ReadToEnd()
            $SQLLocalDBProcessStandardError = $SQLLocalDBProcess.StandardError.ReadToEnd()
        }

        ## Make Wait For Exit call after the ReadToEnd on Output Streams to prevent app deadlock
        ## some apps do not write to out asynchronously and making the wait for exit call before
        ## retrieving output can cause the app deadlock.
        $SQLLocalDBProcess.WaitForExit()

        if($RunAsAdministrator)
        {
            $SQLLocalDBProcessStandardOut = Get-Content -Path $StandardOutFile -ErrorAction SilentlyContinue
            $SQLLocalDBProcessStandardError = Get-Content -Path $ErrorOutFile -ErrorAction SilentlyContinue
        }

        ## Get Exit Code
        $SQLLocalDBProcessExitCode = $SQLLocalDBProcess.ExitCode 

        if($SQLLocalDBProcessExitCode -eq 0 -and -not $SQLLocalDBProcessStandardError)
        {
            Write-Output $SQLLocalDBProcessStandardOut
        }
        else
        {
            if($SQLLocalDBProcessStandardOut)
            {
                Write-Output $SQLLocalDBProcessStandardOut

            }

            Write-Verbose ('exitcode: {0}.' -f $SQLLocalDBProcessExitCode)

            throw $SQLLocalDBProcessStandardError
        }
    }
}