# Importing the module creates a new private connection object.
# TO DO 
# 1. Update Close and Invoke as they currently do not work in the net setup.
# 2. Allow for pipeline input for ALL cmdlets, besides New-SQLConnection... Maybe Get can take pipeline input for name? 
# 3. Create pester tests for module to ensure functionality works.
# 4. Work on naming conventions.

$script:conn = @()


Function New-SQLConnection {

    param(
    [parameter(Mandatory=$true,HelpMessage="Name of connection.")]
    [string]$Name,
    [parameter(ParameterSetName="ConnectionString",Mandatory=$true,HelpMessage="Specify full connection string.")]
    [String]$ConnectionString,
    [parameter(ParameterSetName="ConnectionBuilder",Mandatory=$true,HelpMessage="Server name, specify instace <server>\<instance>")]
    [String]$Server,
    [parameter(ParameterSetName="ConnectionBuilder",HelpMessage="Specify database name.")]
    [String]$Database,
    [parameter(ParameterSetName="ConnectionBuilder",HelpMessage="provide a PS Credential object, if left empty expects a trusted connection.")]
    [PSCredential]$Credential
    )

    $conn = New-Object System.Data.SqlClient.SqlConnection;
    $conn | Add-Member -MemberType NoteProperty -Name Name -Value $Name

    if ($PSCmdlet.ParameterSetName -eq "ConnectionString") {
        Write-Verbose -Message "Opening connection with specified connection string"
        $conn.ConnectionString = $ConnectionString;
    }
    elseif ($PSCmdlet.ParameterSetName -eq "ConnectionBuilder") {

        $db = {if($Database){"with database $($Database)"}}

        if ($Credential) {
            Write-Verbose -Message "Opening connection with credential object to $($Server) $(icm $db )"
            $ConnectionString = "Server={0};Database={1};User Id={2};Password={3};" -f $Server, $Database, 
                $Credential.GetNetworkCredential().UserName, $Credential.GetNetworkCredential().Password
        } else {
            Write-Verbose -Message "Opening trusted connection to $($Server) $(icm $db)"
            $ConnectionString = "Server={0};Database={1};Trusted_Connection=yes;" -f $Server, $Database
                
        }

        $conn.ConnectionString = $ConnectionString;
    }

    $Script:conn += $conn

}

Function Open-SQLConnection {
    [cmdletbinding()]
    param(
    [parameter(Mandatory=$true,HelpMessage="Name of connection.")]
    [string]$Name
    )

    $conn = $script:conn | Where-Object {$_.name -like $Name} 
    $conn.open()    
    
}


Function Set-SQLDatabase {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$name,
        [Parameter(Mandatory=$true)]
        [string]$database
    )


    $conn = $script:conn | Where-Object {$_.name -eq $name}

    try {
        Write-Verbose "Changing database from $($conn.Database) to $database"
        $conn.ChangeDatabase($database)
    } 
    catch {
        Write-Error "$($_.exception)" -Exception PowerSQL.ChangeDatabaseError
    }

}

Function Get-SQLConnection {
    [cmdletbinding()]
    param(
    [string]$name
    )

    if ($name) {
    $script:conn | Where-Object {$_.name -eq $name} 
    }
    else {
    $script:conn
    }

}

Function Invoke-SQLQuery {
    [cmdletbinding()]
    param([string]$query)

    Write-Verbose "executing query against database $($script:conn.database)"
    try {
        $command = $script:conn.CreateCommand()
        $command.CommandText = $query
    }
    catch {
        Write-Error "Unable to create DBcommand"
        break
    }

    Write-Verbose "Creating new datatable"
    $table = new-object “System.Data.DataTable”

    Write-Verbose "Executing reader"
    $data = $command.ExecuteReader()

    Write-Verbose "Loading reader result into datatable"
    $table.load($data)

    $table


}

Function Close-SQLConnection {
    [cmdletbinding()]
    param()
    try {
        Write-Verbose "Closing connection to $($script:conn.DataSource)"
        $script:conn.Close()
    }
    catch {
        Write-Error "Could not close SQL connection" -Exception PowerSQL.CouldNotClose
        break
    }
    $script:closed = $true

}
    