# Power-SQL
Framework to query SQL server databases. 
Requires PowerShell v5 or v4

Open-SQLConnection

. Provide with a Connection String, or a Server, Database and PS Credential object to open a connecton to a DB. 

. $Credential = Get-Credential
. Open-SQLConnection -Server SQLServer -Database MyDatabase -Credential $Credential

Invoke-SQLQuery

. Provide with a SQL query and the cmdlet will go off to query the current DB context.

. Invoke-SQLQuery -Query "Select * from MyTable"

Get-SQLConnection

. Returns the current connection object to the pipeline

Set-SQLDatabase

. Changes the current database in use on the context.

Close-SQLConnection

. Closes the current SQL connection 
