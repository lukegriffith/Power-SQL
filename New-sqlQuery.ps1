function New-SQLQuery {

    param(
    [Parameter(Mandatory=$true)]
        $Query,
    [Parameter(Mandatory=$false)]
        $ConnectionString = "server=Helpdesk_DR;database=supportworks_db_ext;User Id=DataWarehouseUser;Password=Str4da130TCAbaRth*66;trusted_connection=False;"
    )



	

$Stoploop = $false
[int]$Retrycount = "0"
 
do {
	try {
		
	        $DA = New-Object system.Data.SqlClient.SqlDataAdapter($Query,$ConnectionString)
	        $DT = New-Object system.Data.DataTable
	        $DA.Fill($DT) | Out-Null
	        $DA.Dispose() | Out-Null 

		#Write-Host "Job completed"
		$Stoploop = $true
		}
	catch {
		if ($Retrycount -gt 3){
			#Write-Host "Could not send Information after 3 retrys."
			$Stoploop = $true

            $DT = 404   
		}
		else {
			#Write-Host "Could not send Information retrying in 30 seconds..."
			Start-Sleep -Seconds 10
			$Retrycount = $Retrycount + 1
		}
	}
}
While ($Stoploop -eq $false)
    
    return $DT


}