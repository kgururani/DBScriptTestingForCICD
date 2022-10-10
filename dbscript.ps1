
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
	$sql_file= Split-Path -Path "$repo_dir\DataBaseFiles\Version-0\*.sql" -Leaf -Resolve
	##Checking for table existence
	$table_val= sqlcmd -h-1 -S $h -U $uname -P $password -v table= "$d.$table_name" -Q $query
	if($table_val){
		        write-host "PASS: Table exists"
	}
	else{
		    Write-Warning " Table does not exist in DB. Executing first script"
		    $first_script= ($sql_file | Measure -Min).Minimum
		    $first_script
		    $first_script_target= Get-ChildItem "$repo_dir\DataBaseFiles\Version-0\$first_script"
			sqlcmd -S $h -U $uname -P $password -i $first_script_target

	}

	##fetch current version from database table
	$db_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; select CURRENT_VERSION from $d.$table_name" | Format-List | Out-String | ForEach-Object { $_.Trim() }
	$db_sub_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; select SUB_VERSION from $d.$table_name" | Format-List | Out-String | ForEach-Object { $_.Trim() }
	
	write-host "INFO: Version on Db: "$db_version
	write-host "INFO: SUB Version on Db: "$db_sub_version
	for($i=0; $i -le ($sql_folders.length -1); $i +=1){
	
		if($sql_folders[$i] -ne "version-0"){
			$version_num= $sql_folders[$i].split('-')[1]
			write-host "FOLDER VERSION: " $version_num
			write-host "FIRST TIME"
			$version_num_check= $version_num -match '\d{1,3}\.\d{1,3}\.\d{1,3}'
			if($version_num_check -eq 'True'){
				if($version_num -gt $db_version){
					$sql_files= Split-Path -Path "$repo_dir\DataBaseFiles\Version-$version_num\*.sql" -Leaf -Resolve
					for($j=0; $j -le ($sql_files.length -1); $j +=1){
						Write-Host "EXEC: executing script: "$sql_files[$j]
						$sub_version_num= $sql_files[$j].split('-')[0]
						write-host "TEST AGAIN: " $sub_version_num
						$sub_version_num_check= $sub_version_num -match '\d{1,3}'
						if($sub_version_num_check -eq 'True'){
							if($sub_version_num -gt $db_version){
								$exec_file=$sql_files[$j]
								$target=Get-ChildItem "$repo_dir\DataBaseFiles\version-$version_num\$exec_file"
								sqlcmd -S $h -U $uname -P $password -j $target
								##Update current sub version from database table
								sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$table_name" -Q "set nocount on; update $d.$table_name SET SUB_VERSION = $version_num" | Format-List | Out-String | ForEach-Object { $_.Trim() }
								$db_updated_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; select SUB_VERSION from $d.$table_name" | Format-List | Out-String | ForEach-Object { $_.Trim() }
								write-host "INFO: updated version_num: " $db_updated_version
							}
						}
						else {
							Write-Error "ERROR: Filename does not match the format: " $sql_files[$j]
							$sql_file_issue += $sql_files[$j]
						}
					}
					##Update current sub version from database table
					sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$table_name" -Q "set nocount on; update $d.$table_name SET CURRENT_VERSION = $version_num" | Format-List | Out-String | ForEach-Object { $_.Trim() }
					$db_updated_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; select CURRENT_VERSION from $d.$table_name" | Format-List | Out-String | ForEach-Object { $_.Trim() }\
					write-host "INFO: updated version_num: " $db_updated_version
				}
			}
		}
		else {
			Write-Error "ERROR: Foldername does not match the format: " $sql_folders[$i]
			$sql_file_issue += $sql_files[$i]
		}		
	}
	
	if($sql_file_issue -ne ""){
	write-host "Files with issue in name convention"
	$sql_file_issue
	}
}

script-execute

