#Project    MRMS
#Version 	1.0
#read the arguments from the Command Line Interface

param (
	$d,
	$h,
	$uname,
	$branch, 
	$password, 
	$repo_dir,
	$table_name
	)

if(!$d){
	write-host "INFO: Database name is mandatory `nUsage is as follows: `ndb-script -h hostname(default USHYDGSREENIVAS\SQLSERVER) -p port(Default 1433) -uname db_username -password password -d database_name -branch branch_name -repo_dir sql_script_dir -table_name version_check_table)"
}
#checking if environment password is present. 
if((!$password) -and (!$env_passwd)){
	Write-Error "ERROR: Please use enviroment variable $MSPASSWORD or pass the password as a parameter using -p option. Exiting now"
	exit 0
	}
if(!$password){
	write-host "INFO: Using the default environment password"
	$Env:MSPASSWORD=$env_passwd
}
else{
	write-host "INFO: Using the parameter password"
	$Env:MSPASSWORD=$password
}

##connection_check
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
	else {
	        Write-Error "ERROR: Connection failed"
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

	##fetch current version from database table
	$db_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; select CURRENT_VERSION from $d.$table_name" | Format-List | Out-String | ForEach-Object { $_.Trim() }
	$db_sub_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; select SUB_VERSION from $d.$table_name" | Format-List | Out-String | ForEach-Object { $_.Trim() }
	
	write-host "INFO: Current Version on Db: "$db_version
	write-host "INFO: Current Sub Version on Db: "$db_sub_version
	
	for($i=0; $i -le ($sql_folders.length -1); $i +=1){
		write-host "INFO: LOOP:"$i
		if($sql_folders[$i] -ne 'version-0'){
			$version_num= $sql_folders[$i].split('-')[1]
			$version_num_check= $version_num -match '\d{1,3}\.\d{1,3}\.\d{1,3}'
			if($version_num_check -eq 'True'){
			
				if($version_num -ge $db_version){
					$sql_files_count = (Get-ChildItem -File "$repo_dir\DataBaseFiles\version-$version_num\*.sql" | Measure-Object)
					write-host "$sql_files_count::"$sql_files_count
					$sql_files= Split-Path -Path "$repo_dir\DataBaseFiles\version-$version_num\*.sql" -Leaf -Resolve
					write-host "INFO: LOOP FILES:"$sql_files
					for($j=0; $j -le ($sql_files.length -1); $j +=1){
						write-host "INFO: version_num:"$version_num
						write-host "INFO: INSODE LOOP FILES:"$sql_files
						write-host "INFO:INSIDE LOOP:"$j
						write-host "INFO: INSIDE LOOP FILES AGAIN:"$sql_files[$j]
						write-host "INFO:LENGTH of sql_files: "$sql_files.length
						if($sql_files_count -eq '1'){
							write-host "INSIDE IF"
							$sub_version_num= $sql_files.split('-')[0]
						}
						else{
							write-host "INSIDE ELSE"
							$sub_version_num= $sql_files[$j].split('-')[0]
						}
						$sub_version_num_check= $sub_version_num -match '\d{1,3}'
						if($sub_version_num_check -eq 'True'){
							if($version_num -gt $db_version){
								$db_sub_version = '0'
							}
							if($sub_version_num -gt $db_sub_version){
								$exec_file=$sql_files[$j]
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
					##Update current version from database table
					
					
					sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$table_name" -Q "set nocount on; update $d.$table_name SET CURRENT_VERSION = '$version_num'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
					$db_updated_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; select CURRENT_VERSION from $d.$table_name" | Format-List | Out-String | ForEach-Object { $_.Trim() }
					write-host "INFO: Updated version_num: " $db_updated_version
				}
			}
			else {
			Write-Error "ERROR: Foldername does not match the format: " $sql_folders[$i]
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

