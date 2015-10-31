# Importing the module creates a new private connection object.
$conn = New-Object System.Data.SqlClient.SqlConnection;
$closed = $true

Function Open-SQLConnection {
    [cmdletbinding()]
    param(
        [parameter(ParameterSetName="ConnectionString",Mandatory=$true,HelpMessage="Specify full connection string.")]
        [String]$ConnectionString,
        [parameter(ParameterSetName="ConnectionBuilder",Mandatory=$true,HelpMessage="Server name, specify instace <server>\<instance>")]
        [String]$Server,
        [parameter(ParameterSetName="ConnectionBuilder",HelpMessage="Specify database name.")]
        [String]$Database,
        [parameter(ParameterSetName="ConnectionBuilder",HelpMessage="provide a PS Credential object, if left empty expects a trusted connection.")]
        [PSCredential]$Credential
    )

    if ($script:closed -eq $true) {

        if ($PSCmdlet.ParameterSetName -eq "ConnectionString") {
            Write-Verbose -Message "Opening connection with specified connection string"
            $script:conn.ConnectionString = $ConnectionString;
            $script:conn.open();
        }
        elseif ($PSCmdlet.ParameterSetName -eq "ConnectionBuilder") {

            $db = {if($Database){"with database $($Database)"}}

            if ($Credential) {
                Write-Verbose -Message "Opening connection with credential object to $($Server) $(icm $db )"
                $ConnectionString = "Server={0};Database={1};User Id={2};Password={3};" -f $Server, $Database, 
                    $Credential.GetNetworkCredential().UserName, $Credential.GetNetworkCredential().Password
            } else {
                Write-Verbose -Message "Opening trusted connection to $($Server) $(icm $db)"
                $ConnectionString = "Server={0};Database={1};User Id={2};Trusted_Connection=yes;" -f $Server, $Database
                    
            }

            $script:conn.ConnectionString = $ConnectionString;
            $script:conn.open();
        }

    } 
    else {
        Write-Error -Message "Previous connection open" -Exception PowerSQL.ExistingConnection
        Break
    }

    $script:closed = $false
    
}

Function Set-SQLDatabase {
    [cmdletbinding()]
    param(
        $database
    )

    try {
        Write-Verbose "Changing database from $($script:conn.Database) to $database"
        $script:conn.ChangeDatabase($database)
    } 
    catch {
        Write-Error "$($_.exception)" -Exception PowerSQL.ChangeDatabaseError
    }

}

Function Get-SQLConnection {
    [cmdletbinding()]
    param(

    )

    $script:conn
    
}

Function Invoke-Query {
    [cmdletbinding()]
    param(
        [string]$query
    )

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
