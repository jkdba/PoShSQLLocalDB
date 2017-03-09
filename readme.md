# PoShSQLLocalDB
A PowerShell Module for SQLLocalDB binary.

This module is a wrapper around the SQLLocalDB.exe binary.

## Examples:

### Create Instance
##### PowerShell Module Command

    PS> New-SQLLocalDBInstance -InstanceName 'test'
    LocalDB instance "test" created with version 13.0.2151.0.

##### SQLLocalDB Equivalent
    CMD> SQLLocalDB.exe create "test"

### Remove Instance
#### Nicely
##### PowerShell Module Command

    PS> Remove-SQLLocalDBInstance -InstanceName 'test'
    LocalDB instance "test" deleted.

##### SQLLocalDB Equivalent
    CMD> SQLLocalDB.exe delete "test"

#### Forcefully
##### PowerShell Module Command
    PS> Remove-SQLLocalDBInstance -InstanceName 'test'-Force
    LocalDB instance "test" deleted.

##### SQLLocalDB Equivalent
* There is no matching command. The Force flag simply shuts the instance down for you before removing it.

### Start Instance
##### PowerShell Module Command
    PS> Start-SQLLocalDBInstance -InstanceName 'test'
    LocalDB instance "test" started.

##### SQLLocalDB Equivalent
    CMD> SQLLocalDB.exe start "test"

### Stop Instance

#### Nicely
##### PowerShell Module Command
    PS> Stop-SQLLocalDBInstance -InstanceName 'test'
    LocalDB instance "test" stopped.

##### SQLLocalDB Equivalent
    CMD> SQLLocalDB.exe stop "test"

#### Shutdown with NoWait
##### PowerShell Module Command
    PS> Stop-SQLLocalDBInstance -InstanceName 'test' -ShutdownNOWAIT
    LocalDB instance "test" stopped.

##### SQLLocalDB Equivalent
    CMD> SQLLocalDB.exe stop "test" -i

#### Shutdown with Kill External
##### PowerShell Module Command
    PS> Stop-SQLLocalDBInstance -InstanceName 'test' -ExternalKill
    LocalDB instance "test" stopped.

##### SQLLocalDB Equivalent
    CMD> SQLLocalDB.exe stop "test" -k

### Start Trace
##### PowerShell Module Command
    PS> Start-SQLLocalDBTraceAPI

##### SQLLocalDB Equivalent
    CMD> SQLLocalDB.exe trace on

### Stop Trace
##### PowerShell Module Command
    PS> Stop-SQLLocalDBTraceAPI

##### SQLLocalDB Equivalent
    CMD> SQLLocalDB.exe trace off

### Get Instance
#### Get All Instances
##### PowerShell Module Command
    PS> Get-SQLLocalDBInstance
    Name         State   Owner        SharedName LastStartTime       InstancePipeName Version     AutoCreate
    ----         -----   -----        ---------- -------------       ---------------- -------     ----------
    test         Stopped UserAccount  ...        3/9/2017 4:14:10 PM ...              13.0.2151.0 No
    ProjectsV13  Stopped UserAccount  ...        3/6/2017 8:48:40 AM ...              13.0.2151.0 No

##### SQLLocalDB Equivalent
    CMD> SQLLocalDB.exe info

#### Get Specifc Instance
##### PowerShell Module Command
    PS> Get-SQLLocalDBInstance -InstanceName 'test'
    Name         State   Owner        SharedName LastStartTime       InstancePipeName Version     AutoCreate
    ----         -----   -----        ---------- -------------       ---------------- -------     ----------
    test         Stopped UserAccount  ...        3/9/2017 4:14:10 PM ...              13.0.2151.0 No

##### SQLLocalDB Equivalent
    CMD> SQLLocalDB.exe info "test"

### Get SQLLocalDB Versions
##### PowerShell Module Command
    PS> Get-SQLLocalDBVersions
    Version
    -------
    Microsoft SQL Server 2014 (12.0.2000.8)
    Microsoft SQL Server 2016 (13.0.2151.0)

##### SQLLocalDB Equivalent
    CMD> SQLLocalDB.exe versions

### Share Instance
##### PowerShell Module Command
    PS> Add-SQLLocalDBSharedInstance -InstanceName 'test' -SharedInstanceName 'sharetest'
    Private LocalDB instance "test" shared with the shared name: "sharetest".
    WARNING: You must restart the instance: "test" before sharing will take effect.

* `-UserAccount` and `-UserSID` are optional parameters that are the same as passing this info directly to the `SQLLocalDB share` command.

##### SQLLocalDB Equivalent
    CMD> SQLLocalDB.exe share "" "test" "sharetest"

### Unshare Instance
##### PowerShell Module Command
    PS> Remove-SQLLocalDBSharedInstance -SharedInstanceName '.\sharetest'
    Shared LocalDB instance ".\sharetest" unshared.

##### SQLLocalDB Equivalent
    CMD> SQLLocalDB.exe unshare ".\sharetest"