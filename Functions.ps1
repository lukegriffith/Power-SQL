function Connect-sqlDB {
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

        if ($loadSchema) {

        $store.loadSchema()
        }

        $Global:SQLDatabaseContext = $store
        $store

}
