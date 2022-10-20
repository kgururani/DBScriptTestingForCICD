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
	$table_name,
	$versionNumberToExecute
	)
#Checking if Database name is present or not
	if(!$d){
		Write-Error "ERROR: Database field is mandatory. Please provide value on 'db' option in CI/CD Pipeline. Exiting now..."
		exit 0
	}
#Checking if host name is present or not
	if(!$h){
		Write-Error "ERROR: Host field is mandatory. Please provide value on 'hostname' option in CI/CD Pipeline. Exiting now..."
		exit 0
	}
#Checking if user name is present or not
	if(!$uname){
		Write-Error "ERROR: User field is mandatory. Please provide value on 'db_user' option in CI/CD Pipeline. Exiting now..."
		exit 0
	}
#Checking if branch name is present or not
	if(!$branch){
		Write-Error "ERROR: Branch field is mandatory. Please provide value on 'branch' option in CI/CD Pipeline. Exiting now..."
		exit 0
	}
#Checking if password is present or not
	if(!$password){
		Write-Error "ERROR: password field is mandatory. Please provide value on 'password' option in CI/CD Pipeline. Exiting now..."
		exit 0
	}
#Checking if table name is present or not
	if(!$table_name){
		Write-Error "ERROR: Table field is mandatory. Please provide value on 'table_name' option in CI/CD Pipeline. Exiting now..."
		exit 0
	}
#Checking if version name is present or not
	if(!$versionNumberToExecute){
		Write-Error "ERROR: Version field is mandatory. Please provide value on 'versionNumberToExecute' option in CI/CD Pipeline. Exiting now..."
		exit 0
	}
	
#Checking if version type is valid or not
	$version_num_checkTest= $versionNumberToExecute -match '\d{1,3}\.\d{1,3}\.\d{1,3}'
	if(!$version_num_checkTest){
		Write-Error "ERROR: Version field value is invalid. Please provide value on 'x.x.x' format in CI/CD Pipeline where x is version numbers. Exiting now..."
		exit 0
	}

#Checking if repo dir field is present or not
	if(!$repo_dir){
		Write-Error "ERROR: Repo Dir field is mandatory. Please provide value on 'repoDirPath' option in CI/CD Pipeline. Exiting now..."
		exit 0
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
	$connection_check=Test-SqlConnection -ServerName $h -DatabaseName $d -Username $uname -PassWord $password
	if($connection_check){
		write-host "PASS: SQL Connection successfull"
	}
	else{
	    Write-Error "ERROR: Connection failed. Please check the DB field values. Exiting now..."
		exit 0
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


	$query= $("IF OBJECT_ID(N'$d.$table_name', N'U') IS NOT NULL
	        BEGIN
	            PRINT 'True'
            END")
	##Adding sql scripts in repo to array
	$sql_folders = Split-Path -Path "$repo_dir\DataBaseFiles\*" -Leaf -Resolve
	$sql_file= Split-Path -Path "$repo_dir\DataBaseFiles\version-0\*.sql" -Leaf -Resolve
	##Checking for table existence
	$table_val= sqlcmd -h-1 -S $h -U $uname -P $password -v table= "$d.$table_name" -Q $query
	if($table_val){
		write-host "PASS: Version table already exists in DB with table name $d.$table_name "
	}
	else{
	    Write-Warning " Version table does not exist in DB. Creating the table as $d.$table_name"
	    $first_script= ($sql_file | Measure -Min).Minimum
		$first_script
		$first_script_target= Get-ChildItem "$repo_dir\DataBaseFiles\version-0\$first_script"
		sqlcmd -S $h -U $uname -P $password -i $first_script_target
	}

	#Update current version from database table
	sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$table_name" -Q "set nocount on; update $d.$table_name SET CURRENT_VERSION = '$versionNumberToExecute'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
	
	##fetch current version ,previous version and sub-version from database table
	$db_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; select CURRENT_VERSION from $d.$table_name" | Format-List | Out-String | ForEach-Object { $_.Trim() }
	$db_previous_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; select PREVIOUS_VERSION from $d.$table_name" | Format-List | Out-String | ForEach-Object { $_.Trim() }
	$db_sub_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; select SUB_VERSION from $d.$table_name" | Format-List | Out-String | ForEach-Object { $_.Trim() }
	
	if($db_version -ne $db_previous_version){
		#Update current version from database table
		sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$table_name" -Q "set nocount on; update $d.$table_name SET CURRENT_VERSION = '0'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
	}
	write-host "INFO: Current Version on DB: " $db_version
	write-host "INFO: Previous Version on Db: "$db_previous_version
	write-host "INFO: Current Sub Version on Db: "$db_sub_version
	
	for($i=0; $i -le ($sql_folders.count -1); $i +=1){
		write-host "INFO: LOOP:"$i
		if($sql_folders[$i] -ne 'version-0'){
			$version_num= $sql_folders[$i].split('-')[1]
			$version_num_check= $version_num -match '\d{1,3}\.\d{1,3}\.\d{1,3}'
			if($version_num_check -eq 'True'){
				if($version_num -eq $db_version){
					$sql_files= Split-Path -Path "$repo_dir\DataBaseFiles\version-$version_num\*.sql" -Leaf -Resolve
					write-host "INFO: LOOP FILES:"$sql_files
					for($j=0; $j -le ($sql_files.count -1); $j +=1){
						write-host "INFO: version_num:"$version_num
						write-host "INFO: INSODE LOOP FILES:"$sql_files
						write-host "INFO:INSIDE LOOP:"$j
						write-host "INFO: INSIDE LOOP FILES AGAIN:"$sql_files[$j]
						
						if($sql_files.count -eq '1'){
							$sub_version_num= $sql_files.split('-')[0]
						}
						else{
							$sub_version_num= $sql_files[$j].split('-')[0]
						}
						$sub_version_num_check= $sub_version_num -match '\d{1,3}'
						if($sub_version_num_check -eq 'True'){
							if($version_num -gt $db_version){
								$db_sub_version = '0'
							}
							if($sub_version_num -gt $db_sub_version){
								if($sql_files.count -eq '1'){
									$exec_file=$sql_files
								}
								else{
									$exec_file=$sql_files[$j]
								}
								$target=Get-ChildItem "$repo_dir\DataBaseFiles\version-$version_num\$exec_file"
								sqlcmd -S $h -U $uname -P $password -i $target
								##Update current sub version from database table
								sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$table_name" -Q "set nocount on; update $d.$table_name SET SUB_VERSION = '$sub_version_num'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
								$db_updated_sub_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; select SUB_VERSION from $d.$table_name" | Format-List | Out-String | ForEach-Object { $_.Trim() }
								write-host "INFO: Updated Sub version_num: " $db_updated_sub_version
							}
						}
						else {
							Write-Error "ERROR: Filename does not match the format: " $sql_files[$j]
							$sql_file_issue += $sql_files[$j]
						}
					}
					##Update previous version from database table
					sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$table_name" -Q "set nocount on; update $d.$table_name SET PREVIOUS_VERSION = '$version_num'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
					$db_previous_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; select CURRENT_VERSION from $d.$table_name" | Format-List | Out-String | ForEach-Object { $_.Trim() }
					write-host "INFO: Updated version_num: " $db_previous_version
				}
				Write-Error "ERROR: Such Folder does not exist, please check the name again: " $sql_folders[$i]

			}
			else {
			Write-Error "ERROR: Foldername does not match the format, Please check the format again : " $sql_folders[$i]
			$sql_file_issue += $sql_files[$i]
			}	
		}
			
	}
	
	if($sql_file_issue -ne ""){
	write-host "Files with issue in name convention"
	$sql_file_issue
	}
}

script-execute

