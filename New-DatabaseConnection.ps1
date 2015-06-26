<#
.Synopsis
   This cmdlet is used to create an object that auto generates connection strings for SQL connectors
.DESCRIPTION
   Long description
.EXAMPLE
    $credential = Get-AccountPassword -PasswordProxyWS $ws -CIName MonitoringUK6_Database -AccountName DevOps_ReadOnly | select -ExpandProperty object
    New-DatabaseConnection -hostname MonitoringUK6_Database -database DevOps -username $credential.UserName -password $credential.Password
.EXAMPLE
   $credential = Get-ManagePassword -PasswordProxyWS $ws -CIName database
   New-DatabaseConnection -hostname MonitoringUK6_Database -database DevOps -credential $credential
.INPUTS
   
.OUTPUTS
   
.NOTES
   
.COMPONENT
   
.ROLE
   
.FUNCTIONALITY
   Used to create connection strings for SQL connectors 
#>
function New-DatabaseConnection
{
    [CmdletBinding()]
    Param
    (
        # hostname of database server
        [Parameter(Mandatory=$true)]
        [string]$hostname,
        # database to be used
        [Parameter(Mandatory=$true)]
        [string]$database,
        # credentials stored in PSCredential
        [Parameter(Mandatory=$false)]
        $credential,
        # username for connection string
        [Parameter(Mandatory=$false)]
        [string]$username,
        # password for connection string
        [Parameter(Mandatory=$false)]
        [string]$password
    )



    if ($credential) {

        $userName = $credential.GetNetworkCredential().UserName
        $password = $credential.GetNetworkCredential().Password

        $obj = "" | select hostname, username, password, database, connectionstring
        $obj.hostname = $hostname
        $obj.username = $username
        $obj.password = $password
        $obj.database = $database
        $obj.connectionstring = "server=$($obj.hostname);database=$($obj.database);User Id=$($obj.username);Password=$($obj.password);trusted_connection=False;Application Name=""Power-SQLps4";""

        return $obj
        
    }
    else {

        $obj = "" | select hostname, username, password, database, connectionstring
        $obj.hostname = $hostname
        $obj.username = $username
        $obj.password = $password
        $obj.database = $database
        $obj.connectionstring = "server=$($obj.hostname);database=$($obj.database);User Id=$($obj.username);Password=$($obj.password);trusted_connection=False;Application Name='Power-SQLps4';"

        return $obj

    }
    
}

