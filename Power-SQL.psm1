<#

PowerSQL is used to help query SQL Servers, by generating connection strings, obtaining tables and columns then allowing you to query.
Build on PowerShell v5

#>

# Imports PS1 files from script root
if ($psversiontable.psversion.major -eq 5)
{
Get-ChildItem -Path $PSScriptRoot\*.ps1 | Foreach-Object{ . $_.FullName }	
}
elseif ($psversiontable.psversion.major -eq 4){
Get-ChildItem $PSScriptRoot\*ps1 | Where-Object name -notlike "Class*" | Foreach-Object{ . $_.FullName }	

}