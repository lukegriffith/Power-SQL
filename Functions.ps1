
<#
.Synopsis
   Makes a connection to SQL Server via PowerSQL
.DESCRIPTION
   Connects to a SQL database, running basic connectivity tests and connection string generation. This creates a global variable $SQLDatabaseContext, that stores tables, views, details and a tablecache of last query ran. 
.EXAMPLE
    Connect-PowerSQL -hostname sql\Blackadder -database AdventureWorksDB -Credentials $cred -loadSchema 
    # Load schema switch, loads tables and views with columns and datatypes. 
   
.EXAMPLE

   Connect-PowerSQL -hostname sql\Blackadder -database AdventureWorksDB -username Blam -password Blooom
.EXAMPLE
   Connect-PowerSQL -hostname sql\Blackadder -database AdventureWorksDB 
   # Trusted connection

.INPUTS
   HOSTNAME: Input server, instance and port <Server>\<Instance>:<Port> 
    EG 
    sql\Blackadder
    OR
    sql\Blackadder:1433

   DATABASE: database on instance you're connecting to. 
   LoadSchema switch: This iniiates a load of all tables and columns 

   Credentials: Accepts a pscredentails object

   username / password  : string username and password

.OUTPUTS
   This cmdlet sets a global variable $SQLDatabaseContext, that is used by default by Invoke-PowerSQL, and also outputs the object back to the shell, to allow you to save to your own variable.
   Invoke-PowerSQL allows you to specify data context via, see help on Invoke-PowerSQL
.NOTES
   Still a work in progress, looking to add functonality to list databases from instance.
#>
function Connect-PowerSQL {
    [cmdletbinding(DefaultParameterSetName="Trusted")]
    param(
        [parameter(mandatory=$true)]
        [string]$hostname,
        [parameter(mandatory=$true)]
        [string]$database,
        [switch]$loadSchema,
        [parameter(parameterSetName="PSCredential")]
        [pscredential]$Credentials,
        [parameter(parameterSetNAme="username")]
        [string]$username,
        [string]$password
        )

        if ($PSCmdlet.ParameterSetName -eq "Trusted") {$store = [DatabaseConnection]::new($hostname,$database, $true)}
        elseif ($PSCmdlet.ParameterSetName -eq "PSCredential") {$store = [DatabaseConnection]::new($hostname,$database,$Credentials)}
        elseif ($PSCmdlet.ParameterSetName -eq "username") { if ($username -and $password) { $store = [DatabaseConnection]::new($hostname,$database,$username,$password) } else { Write-Error -Exception UsernameOrPassword -Message "missing $(if (!$username){"username"}else{"password"})"}} 
        else { Write-Error -Exception sqlModuleException -Message "Something has gone horribly wrong" } 

        try {
        $store.ConnectionTest()
        } catch { break; }


        if ($loadSchema) {

        $store.loadSchema()
        }

        $Global:SQLDatabaseContext = $store
        $store

}

<#
.Synopsis
   Runs .Query function of default database context $SQLDatabaseContext, or context specified in parameters
.DESCRIPTION
   Executes TSQL queries against database object
.EXAMPLE
   Invoke-PowerSQL "select * from Production.Product" 
   # This will use the default context, set from Connect-PowerSQL (Global variable $SQLDatabaseContext)
.EXAMPLE
   Invoke-PowerSQL -path .\Query1.sql -PowerSQLContext $database
   # This will take a object produced by Connect-PowerSQL, and query that instead of the default context currently set in memory. 
.NOTES
   Still a work in progress, looking to add PS Session proxy.
#>
function Invoke-PowerSQL {
    [cmdletbinding(DefaultParameterSetName="stringQuery")]
    param (
        [parameter(position=0)]
        [string]$query,
        [parameter(parameterSetName="File")]
        [string]$path,
        [parameter(parameterSetName="SpecifiedContext")]
        [DatabaseConnection]$PowerSQLContext
    )

    if (!$Global:SQLDatabaseContext -and !$PowerSQLContext) { Write-Error -Exception Power-SQL:DatabaseNotConnected -Message "no context proivded. Maybe`$GLOBAL:SQLDatabaseContext not set, run Connect-sqlDB"; break}

    if ($PSCmdlet.ParameterSetName -eq "stringQuery") { $Global:SQLDatabaseContext.query($query) }
    if ($PSCmdlet.ParameterSetName -eq "File") { $query = Get-Item $Path | Get-Content; $Global:SQLDatabaseContext.query($query) }

    if ($PowerSQLContext) {

        if ($path) { $query = Get-Item $path | Get-Content }
        $PowerSQLContext.query($query)
    }


}