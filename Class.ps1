class DatabaseConnection {

    [string]$hostname
    [string]$database
    [bool]$trusted = $false
    [bool]$connectionStatus
    [string]$connectionString
    [array]$tables
    [array]$views
    [system.Data.DataTable]$Tablecache

    

    databaseConnection( [string]$hostname,[string]$database,[bool]$trusted ){
        
        $this.hostname = $hostname
        $this.database = $database
        $this.trusted = $trusted
        $this.connectionString = "Server=$hostname;Database=$database;Trusted_Connection=$($trusted.tostring());"
        

        # Tables logic 
        
    

    }
    
    databaseConnection( [string]$hostname,[string]$database,[pscredential]$SQLcredentials){
    

        $password = $SQLcredentials.GetNetworkCredential().Password
        $username = $SQLcredentials.GetNetworkCredential().UserName


        $this.hostname = $hostname
        $this.database = $database
        $this.connectionString = "Server=$hostname;Database=$database;User Id=$username;Password=$password;"

    }

    databaseConnection( [string]$hostname,[string]$database,[string]$username,[string]$password){
    

        $this.hostname = $hostname
        $this.database = $database
        $this.connectionString = "Server=$hostname;Database=$database;User Id=$username;Password=$password"
        
        
    }

    [system.Data.DataTable]query ($Query){

            $Retrycount = 0
            $retry = $false
            do {
              
            try { 
	            $DA = New-Object system.Data.SqlClient.SqlDataAdapter($Query,$this.connectionString)
	            $this.Tablecache = New-Object system.Data.DataTable
	            $DA.Fill($this.Tablecache) | Out-Null
	            $DA.Dispose() | Out-Null
            } catch { 
        
        
        		    if ($Retrycount -gt 3){
			
			                $retry = $true
                            $DT = 404   
        		    }
		            else {
			
			                Start-Sleep -Seconds 10
			                $Retrycount = $Retrycount + 1
		                 }

            }

            } while ($retry -eq $true)
              
              return $this.Tablecache

    }

    [void]loadSchema() {

        $cacheTable = $this.Query("select * from INFORMATION_SCHEMA.TABLES")
        $this.query("select * from INFORMATION_SCHEMA.Columns where TABLE_CATALOG = '$($this.database)'")
        $store = foreach ($table in $cacheTable) { [Table]::New($table, $this.Tablecache) }
        $this.views = $store | Where-Object {$_.type -eq "VIEW"}
        $this.tables = $store | Where-Object {$_.type -ne "VIEW"}


    }


}


class Table {



    [string]$schema
    [string]$tableName
    [string]$type
    [system.object]$columns

    name(){ "$($this.schema)\$($this.tableName)" }

    Table([System.Data.DataRow]$table, [System.Data.DataTable]$columns) {

        #$this = $self
        $this.schema = $table.TABLE_SCHEMA
        $this.tableName = $table.TABLE_NAME
        $this.type = $table.TABLE_TYPE
        $this.columns = $columns.where{$_.TABLE_SCHEMA -eq $table.TABLE_SCHEMA -and $_.TABLE_NAME -eq $table.TABLE_NAME} | select @{name='ColumnName';expression={$_.COLUMN_NAME}},@{name='DataType';expression={$_.DATA_TYPE}}

    
    
    }

}
