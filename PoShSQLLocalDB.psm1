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

function Get-SQLLocalDBInstanceInformation
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
        $Command = 'info {0}' -f $InstanceName
        $Results = Invoke-SQLLocalDBCommand -CommandParameters $Command
        $Lines = $Results -split "`n"
        $OutputObject = New-Object -TypeName PSObject; 
        $Lines |  ForEach-Object { 
            if($_ -ne '')
            { 
                $Prop = [regex]::Match($_,'^.*?(?=:)').Value
                $Value = [regex]::Match($_,'(?<=\w:).+$').Value -replace '^ +'
                $OutputObject | Add-Member -MemberType NoteProperty -Name $Prop -Value $Value  
            }
        }
        $OutputObject
    }
}

function Get-SQLLocalDBInstance
{
    [CmdletBinding()]
    param
    (
    )
    process
    {
        $Command = 'info'
        $Results = Invoke-SQLLocalDBCommand -CommandParameters $Command
        $Lines = $Results -split "`n"
        $Lines |  ForEach-Object { 
            if($_ -ne '')
            {   
                $OutputObject = New-Object -TypeName PSObject
                $OutputObject | Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value $_
                $OutputObject
            }
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

function Set-SQLLocalDBInstanceShared
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
        Invoke-SQLLocalDBCommand -CommandParameters $Command
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
        [String] $CommandParameters
    )
    begin
    {
        ##
    }
    process
    {
        ## Build Process Start Information
        $ProcessInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo
        $ProcessInfo.FileName = 'SQLLocalDB.exe'
        $ProcessInfo.RedirectStandardError = $true
        $ProcessInfo.RedirectStandardOutput = $true
        $ProcessInfo.UseShellExecute = $false
        $ProcessInfo.Arguments = $CommandParameters

        ## Build and Start Process
        $SQLLocalDBProcess = New-Object -TypeName System.Diagnostics.Process
        $SQLLocalDBProcess.StartInfo = $ProcessInfo
        $SQLLocalDBProcess.Start() | Out-Null

        ## Get Outputs
        $SQLLocalDBProcessStandardOut = $SQLLocalDBProcess.StandardOutput.ReadToEnd()
        $SQLLocalDBProcessStandardError = $SQLLocalDBProcess.StandardError.ReadToEnd()

        ## Make Wait For Exit call after the ReadToEnd on Output Streams to prevent app deadlock
        ## some apps do not write to out asynchronously and making the wait for exit call before
        ## retrieving output can cause the app deadlock.
        $SQLLocalDBProcess.WaitForExit()

        ## Get Exit Code
        $SQLLocalDBProcessExitCode = $SQLLocalDBProcess.ExitCode 

        if($SQLLocalDBProcessExitCode -eq 0)
        {
            Write-Output $SQLLocalDBProcessStandardOut
        }
        else
        {
            throw $SQLLocalDBProcessStandardError
        }
    }
}