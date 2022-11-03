
						if($sql_files.count -eq '1'){
							$sub_version_num= $sql_files.split('-')[0]
						}
						else{
							$sub_version_num= $sql_files[$j].split('-')[0]
						}
						$sub_version_num_check= $sub_version_num -match '\d{1,3}'
						if($sub_version_num_check){
							write-host "sub_version_num: [int]$sub_version_num & db_files_seq:: [int]$db_files_seq"
							if([int]$sub_version_num -gt [int]$db_files_seq){
								if($sql_files.count -eq '1'){
									$exec_file=$sql_files
								}
								else{
									$exec_file=$sql_files[$j]
								}
								$target=Get-ChildItem "$repo_dir\DataBaseFiles\version-$version_num\$exec_file"
								$message = sqlcmd -S $h -U $uname -P $password -i $target -m 1
								try{
									$message=$message.replace("'",'')
								}
								catch{
									$message=$message
								}
								if($message -like "*Msg*"){
									sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table" -Q "set nocount on; UPDATE $d.$version_table SET MESSAGE = 'ERROR:' + '$message' " | Format-List | Out-String | ForEach-Object { $_.Trim() }
									exit 1
								}
								else{
									sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table" -Q "set nocount on; UPDATE $d.$version_table SET MESSAGE = 'SUCCESS'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
								}
								##UPDATE current sub version from database table
								sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table" -Q "set nocount on; UPDATE $d.$version_table SET LAST_EXECUTED_FILE_VERSION = '$sub_version_num'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
								$db_UPDATEd_sub_version=sqlcmd -h-1 -S $h -U $uname -P $password -Q "set nocount on; SELECT LAST_EXECUTED_FILE_VERSION from $d.$version_table" | Format-List | Out-String | ForEach-Object { $_.Trim() }
								#UPDATE number of files executed from database table
								sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table_logs" -Q "set nocount on; UPDATE $d.$version_table_logs SET EXECUTED_FILE_VERSION = '$db_UPDATEd_sub_version' WHERE VERSIONS = '$db_version'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
								
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
						sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table_logs" -Q "set nocount on; INSERT INTO $d.$version_table_logs(VERSIONS,EXECUTED_FILE_VERSION) VALUES ('$db_version','$db_UPDATEd_sub_version') " | Format-List | Out-String | ForEach-Object { $_.Trim() }
					
					}

					
					
				}
				
			}
			else {
				sqlcmd -h-1 -S $h -U $uname -P $password -v table = "$d.$version_table" -Q "set nocount on; UPDATE $d.$version_table SET MESSAGE = 'ERROR: $sql_folders[$i] Foldername does not match the format, Please check the format again..'" | Format-List | Out-String | ForEach-Object { $_.Trim() }
				Write-Error "ERROR: $sql_folders[$i] Foldername does not match the format, Please check the format again.."
				$sql_file_issue += $sql_files[$i]
				exit 1
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

