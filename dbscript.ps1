#Project    MRMS
#Version 	1.1
#read the arguments from the Command Line Interface

param (
	$d,
	$h,
	$uname,
	$branch, 
	$password, 
	$repo_dir,
	$versionNumberToExecute
	)
#Checking if Database name is present or not
	if(!$d){
		Write-Error "ERROR: Database field is mandatory. Please provide value on 'db' option in CI/CD Pipeline. Exiting now..."
		exit 1
	}
#Checking if host name is present or not
	if(!$h){
		Write-Error "ERROR: Host field is mandatory. Please provide value on 'hostname' option in CI/CD Pipeline. Exiting now..."
		exit 1
	}
#Checking if user name is present or not
	if(!$uname){
		Write-Error "ERROR: User field is mandatory. Please provide value on 'db_user' option in CI/CD Pipeline. Exiting now..."
		exit 1
	}
#Checking if branch name is present or not
	if(!$branch){
		Write-Error "ERROR: Branch field is mandatory. Please provide value on 'branch' option in CI/CD Pipeline. Exiting now..."
		exit 1
	}
#Checking if password is present or not
	if(!$password){
		Write-Error "ERROR: password field is mandatory. Please provide value on 'password' option in CI/CD Pipeline. Exiting now..."
		exit 1
	}

#Checking if version name is present or not
	if(!$versionNumberToExecute){
		Write-Error "ERROR: Version field is mandatory. Please provide value on 'versionNumberToExecute' option in CI/CD Pipeline. Exiting now..."
		exit 1
	}
	
#Checking if version type is valid or not
	$version_num_checkTest= $versionNumberToExecute -match '\d{1,3}\.\d{1,3}\.\d{1,3}'
	if(!$version_num_checkTest){
		Write-Error "ERROR: Version field value is invalid. Please provide value on 'x.x.x' format in CI/CD Pipeline where x is version numbers. Exiting now..."
		exit 1
	}

#Checking if repo dir field is present or not
	if(!$repo_dir){
		Write-Error "ERROR: Repo Dir field is mandatory. Please provide value on 'repoDirPath' option in CI/CD Pipeline. Exiting now..."
		exit 1
	}

## SQL Connection_check
function Test-SqlConnection {
param(
      [Parameter(Mandatory)]
      [string]$ServerName,
      [Parameter(Mandatory)]
      [string]$DatabaseName,
      [Parameter(Mandatory)]
      [string]$UserName,
      [Parameter(Mandatory)]
      [string]$PassWord 
     )
      $ErrorActionPreference = 'Stop'
try {
      $connectionString = 'Data Source={0};database={1};User ID={2};Password={3}' -f $ServerName,$DatabaseName,$userName,$PassWord
      $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
      $sqlConnection.Open()
## This will run if the Open() method does not throw an exception
    $true
} 	catch {
    $false
	}
	finally {
## Close the connection when we're done
$sqlConnection.Close()
	}
}

function script-execute {
	$version_table = 'dbo.PIPELINE_CICD_CODE_VERSION'
	$version_table_logs = 'dbo.PIPELINE_CICD_VERSION_LOGS'
	$connection_check=Test-SqlConnection -ServerName $h -DatabaseName $d -Username $uname -PassWord $password
	if($connection_check){
		write-host "PASS: SQL Connection successfull"
	}
	else{
	    Write-Error "ERROR: Connection failed. Please check the DB field values. Exiting now..."
		exit 1
	}

	if(!$branch){
		        write-host "INFO: No branch provided to pull `n[WARNING]: This repo might be stale. Ensure using branch details to pull the latest data"
	}
	else {
		        git -C $repo_dir pull origin $branch
	}
	##Declare array for sql files
	$sql_files= @()
	$sql_file_sort= @()
	$sql_file_issue= @()


	$query= $("IF OBJECT_ID(N'$d.$version_table', N'U') IS NOT NULL
	        BEGIN
	            PRINT 'True'
            END")
	##Adding sql scripts in repo to array
	$sql_folders = Split-Path -Path "$repo_dir\DataBaseFiles\*" -Leaf -Resolve
	$sql_file= Split-Path -Path "$repo_dir\DataBaseFiles\version-0\*.sql" -Leaf -Resolve
	##Checking for table existence
	$table_val= sqlcmd -h-1 -S $h -U $uname -P $password -v table= "$d.$version_table" -Q $query
	if($table_val){
		write-host "PASS: Version table and Version log table already exists in DB with table names 1. $d.$version_table ,2. $d.$version_table_logs"
	}
	else{
	    Write-Warning " Version table does not exist in DB. Creating the table as $d.$version_table"
	    $first_script= ($sql_file | Measure -Min).Minimum
		$first_script
		$first_script_target= Get-ChildItem "$repo_dir\DataBaseFiles\version-0\$first_script"
		sqlcmd -S $h -U $uname -P $password -i $first_script_target
	}

	#UPDATE previous and current version from database table
	$db_current_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; SELECT CURRENT_VERSION from $d.$version_table" | Format-List | Out-String | ForEach-Object { $_.Trim() }
	sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table" -Q "set nocount on; UPDATE $d.$version_table SET PREVIOUS_VERSION = '$db_current_version'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
	sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table" -Q "set nocount on; UPDATE $d.$version_table SET CURRENT_VERSION = '$versionNumberToExecute'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
	##fetch current version ,previous version and sub-version from database table
	$db_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; SELECT CURRENT_VERSION from $d.$version_table" | Format-List | Out-String | ForEach-Object { $_.Trim() }

	$db_previous_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; SELECT PREVIOUS_VERSION from $d.$version_table" | Format-List | Out-String | ForEach-Object { $_.Trim() }
	write-host "INFO: Previous Version on Db: "$db_previous_version
	write-host "INFO: Current Version on DB: " $db_version
	if($db_version -ne $db_previous_version){
		#Check if version is already exist
		#$count_Rows = sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; SELECT COUNT(*) from $d.$version_table_logs WHERE VERSIONS = $db_version" | Format-List | Out-String | ForEach-Object { $_.Trim() }
		write-host "INFO: count_Rows::::ount_Rows"
	}
	
}

script-execute

