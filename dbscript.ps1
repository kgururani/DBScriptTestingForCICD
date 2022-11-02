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
	if($db_version -ne $db_previous_version){
		#Check if version is already exist
		$count_Rows = sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; SELECT COUNT(*) from $d.$version_table_logs WHERE VERSIONS = '$db_version' " | Format-List | Out-String | ForEach-Object { $_.Trim() }
		if($count_Rows -eq '1'){
			#UPDATE number of files executed from database table
			$number_Of_Files_Executed =sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table_logs" -Q "set nocount on; SELECT NUMBER_OF_FILES_EXECUTED from $d.$version_table_logs WHERE VERSIONS = '$db_version'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
			sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table" -Q "set nocount on; UPDATE $d.$version_table SET EXECUTED_FILE_SEQ = '$number_Of_Files_Executed' " | Format-List | Out-String | ForEach-Object { $_.Trim() }
		}
		else{
			sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table" -Q "set nocount on; update $d.$version_table SET EXECUTED_FILE_SEQ = '0'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
		}
	}
	$db_files_seq=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; SELECT EXECUTED_FILE_SEQ from $d.$version_table" | Format-List | Out-String | ForEach-Object { $_.Trim() }

	write-host "INFO: Previous Version on Db: "$db_previous_version
	write-host "INFO: Current Version on DB: " $db_version
	write-host "INFO: Executed Files Sequence Number: "$db_files_seq
	$checkFolderExist = $false

	for($i=0; $i -le ($sql_folders.count -1); $i +=1){		

		if($sql_folders[$i] -ne 'version-0'){		
			$version_num= $sql_folders[$i].split('-')[1]
			$version_num_check= $version_num -match '\d{1,3}\.\d{1,3}\.\d{1,3}'
			if($version_num_check){
				if($version_num -eq $db_version){
					write-host "INFO: 11"
					$checkFolderExist = $true
					$sql_files= Split-Path -Path "$repo_dir\DataBaseFiles\version-$version_num\*.sql" -Leaf -Resolve
					for($j=0; $j -le ($sql_files.count -1); $j +=1){
						if($sql_files.count -eq '1'){
							$sub_version_num= $sql_files.split('-')[0]
						}
						else{
							$sub_version_num= $sql_files[$j].split('-')[0]
						}
						$sub_version_num_check= $sub_version_num -match '\d{1,3}'
						if($sub_version_num_check){
							write-host "INFO: 22 -- $sub_version_num" 
							if([int]$sub_version_num -gt [int]$db_files_seq){
								write-host "INFO: 33"
								if($sql_files.count -eq '1'){
									$exec_file=$sql_files
								}
								else{
									$exec_file=$sql_files[$j]
								}
								write-host "INFO: 44"
								$target=Get-ChildItem "$repo_dir\DataBaseFiles\version-$version_num\$exec_file"
								$message = sqlcmd -S $h -U $uname -P $password -i $target
								write-host "MESSAGE::: $message"
								if($message -like "*Msg*"){
									sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table" -Q "set nocount on; UPDATE $d.$version_table SET MESSAGE = 'ERROR: Please check sql file'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
									exit 0
								}
								else{
									sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table" -Q "set nocount on; UPDATE $d.$version_table SET MESSAGE = 'SUCCESS'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
								}
								##UPDATE current sub version from database table
								sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table" -Q "set nocount on; UPDATE $d.$version_table SET EXECUTED_FILE_SEQ = '$sub_version_num'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
								$db_UPDATEd_sub_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; SELECT EXECUTED_FILE_SEQ from $d.$version_table" | Format-List | Out-String | ForEach-Object { $_.Trim() }
								#UPDATE number of files executed from database table
								sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table_logs" -Q "set nocount on; UPDATE $d.$version_table_logs SET NUMBER_OF_FILES_EXECUTED = '$db_UPDATEd_sub_version' WHERE VERSIONS = '$db_version'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
								i
							}
						}
						else {
							Write-Error "ERROR: Filename does not match the format: " $sql_files[$j]
							$sql_file_issue += $sql_files[$j]
						}
					}
					#Check if version is already exist
					$count_Rows_version = sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; SELECT COUNT(*) from $d.$version_table_logs WHERE VERSIONS = '$db_version' " | Format-List | Out-String | ForEach-Object { $_.Trim() }
					if($count_Rows_version -eq '1'){
						
					}
					else{
						#Insert version number and number of files executed from database table
						sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table_logs" -Q "set nocount on; INSERT INTO $d.$version_table_logs(VERSIONS,NUMBER_OF_FILES_EXECUTED) VALUES ('$db_version','$db_UPDATEd_sub_version') " | Format-List | Out-String | ForEach-Object { $_.Trim() }
					
					}

					
					
				}
				
			}
			else {
				sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table" -Q "set nocount on; UPDATE $d.$version_table SET MESSAGE = 'ERROR: $sql_folders[$i] Foldername does not match the format, Please check the format again..'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
				Write-Error "ERROR: $sql_folders[$i] Foldername does not match the format, Please check the format again.."
				$sql_file_issue += $sql_files[$i]
			}	
		}	
	}
	if(!$checkFolderExist){
		sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table" -Q "set nocount on; UPDATE $d.$version_table SET MESSAGE = 'ERROR: No such folder exist which contains version 2.6.7 , please check again..'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
		Write-Error "ERROR: No such folder exist which contains version $db_version , please check again.. "
		exit 1
	}
	if($sql_file_issue -ne ""){
	write-host "Files with issue in name convention"
	$sql_file_issue
	}
}

script-execute

