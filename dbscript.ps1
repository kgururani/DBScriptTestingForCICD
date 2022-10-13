
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

