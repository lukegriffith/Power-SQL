# Importing the module creates a new private connection object.
# TO DO 
# 1. Create pester tests for module to ensure functionality works.
# 2. Work on naming conventions.

$script:conn = @()

[System.Data.SqlClient.SqlConnection]$script:defaultConn

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
        [PSCredential]$Credential,
        [parameter(HelpMessage="Set context as default connection")]
        [switch]$SetAsDefault
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

    if ($SetAsDefault) {
        Write-Verbose "Setting conenction as default"
        $script:defaultConn = $conn
    }

}

Function Open-SQLConnection {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true,HelpMessage="Name of connection.")]
        [string]$Name
    )

    Process {
        $conn = $script:conn | Where-Object {$_.name -like $Name} 
        
        if ($conn -and $conn.State -eq "Closed") {
            Write-Verbose "Opening Connection to database $($conn.Database)." # Verbose Stream isn't working

            $conn.open()    
        } 
        else {
            Write-Verbose "Connection is already open."
        }
    }
    
}


Function Set-SQLConnection {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$name,
        [string]$database,
        [switch]$SetAsDefault
    )


    $conn = $script:conn | Where-Object {$_.name -like $name}


    if ($database) {
        try {
            Write-Verbose "Changing database from $($conn.Database) to $database"
            $conn.ChangeDatabase($database)
        } 
        catch {
            Write-Error "$($_.exception)" -Exception PowerSQL.ChangeDatabaseError
        }
    }

    if ($SetAsDefault) {
        Write-Verbose "Set $name connection as default"
        $script:defaultConn = $conn
    }

}

Function Get-SQLConnection {
    [cmdletbinding()]
    param(
        [string]$name
    )

    if ($name) {
        $script:conn | Where-Object {$_.name -like $name} 
    }
    else {
        $script:conn
    }

}

Function Invoke-SQLQuery {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName=$true, Mandatory=$true)]
        [string]$Name,
        [parameter(Mandatory=$true)]
        [string]$query
    )

    Process {


        if ($name) {
            $conn = $script:conn | Where-Object {$_.name -like $name} 
        }
        elseif($script:defaultConn) {
            $conn = $script:defaultConn
        } else {
            Write-Error "Please specify connection"
        }

        Write-Verbose "executing query against database $($conn.database)"
        try {
            $command = $conn.CreateCommand()
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

}

Function Close-SQLConnection {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory=$true)]
        $Name
    )


    Process {

        $conn = $script:conn | Where-Object {$_.Name -like $Name}
        try {
            Write-Verbose "Closing connection to $($script:conn.DataSource)"

            if ($conn.state -eq "Open") {
                $conn.Close()
            }
        }
        catch {
            Write-Error "Could not close SQL connection" -Exception PowerSQL.CouldNotClose
            break
        }

        
    }
}
    