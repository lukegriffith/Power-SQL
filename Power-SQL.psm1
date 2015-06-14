<#

PowerSQL is used to help query SQL Servers, by generating connection strings, obtaining tables and columns then allowing you to query.
Build on PowerShell v5

#>

# Imports PS1 files from script root
Get-ChildItem -Path $PSScriptRoot\*.ps1 | Foreach-Object{ . $_.FullName }	

