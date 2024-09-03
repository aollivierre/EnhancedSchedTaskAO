# function Unregister-ScheduledTaskWithLogging {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$TaskName,

#         [Parameter(Mandatory = $true)]
#         [string]$TaskPath
#     )

#     Begin {
#         Write-EnhancedLog -Message "Starting Unregister-ScheduledTaskWithLogging function" -Level "Notice"
#         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
        
#         # Ensure TaskPath starts and ends with a backslash
#         if ($TaskPath -and -not $TaskPath.StartsWith("\")) {
#             $TaskPath = "\" + $TaskPath
#         }
#         if ($TaskPath -and -not $TaskPath.EndsWith("\")) {
#             $TaskPath += "\"
#         }
#     }

#     Process {
#         try {
#             # Construct the arguments array for schtasks.exe
#             $schtasksArgs = @('/Delete', '/TN', "$TaskPath$TaskName", '/F')

#             # Call schtasks.exe to delete the task
#             Write-EnhancedLog -Message "Attempting to delete task using schtasks.exe..." -Level "INFO"
#             $schtasksResult = & schtasks.exe $schtasksArgs 2>&1

#             if ($schtasksResult -like '*The system cannot find the file specified*') {
#                 Write-EnhancedLog -Message "schtasks.exe error: $schtasksResult" -Level "ERROR"
#             }

#             # Verify if the task still exists using Get-ScheduledTask
#             $taskExists = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue
#             if ($taskExists) {
#                 Write-EnhancedLog -Message "Task '$TaskPath$TaskName' still exists after schtasks.exe attempt. Falling back to PowerShell..." -Level "WARNING"
                
#                 # Use PowerShell to remove the task
#                 Unregister-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -Confirm:$false -ErrorAction Stop
#                 Write-EnhancedLog -Message "Task '$TaskPath$TaskName' removed successfully using PowerShell." -Level "INFO"
#             } else {
#                 Write-EnhancedLog -Message "Task '$TaskPath$TaskName' successfully removed using schtasks.exe." -Level "INFO"
#             }
#         }
#         catch {
#             Write-EnhancedLog -Message "Error occurred while removing task '$TaskPath$TaskName': $($_.Exception.Message)" -Level "ERROR"
#             Handle-Error -ErrorRecord $_
#             throw $_
#         }
#     }

#     End {
#         Write-EnhancedLog -Message "Exiting Unregister-ScheduledTaskWithLogging function" -Level "Notice"
#     }
# }

# # Example usage
# $TaskPath = "AAD Migration"
# $TaskName = "Run Post-migration cleanup"
# Unregister-ScheduledTaskWithLogging -TaskPath $TaskPath -TaskName $TaskName



# function Validate-TaskPath {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$TaskPath
#     )

#     Begin {
#         Write-EnhancedLog -Message "Starting Validate-TaskPath function" -Level "Notice"
#         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
#     }

#     Process {
#         # Ensure TaskPath starts with a backslash
#         if (-not $TaskPath.StartsWith("\")) {
#             Write-EnhancedLog -Message "TaskPath must start with a backslash. Invalid TaskPath: '$TaskPath'" -Level "ERROR"
#             throw "Invalid TaskPath format: '$TaskPath'. TaskPath must start with a backslash."
#         }

#         # Ensure TaskPath ends with a backslash
#         if (-not $TaskPath.EndsWith("\")) {
#             Write-EnhancedLog -Message "TaskPath must end with a backslash. Invalid TaskPath: '$TaskPath'" -Level "ERROR"
#             throw "Invalid TaskPath format: '$TaskPath'. TaskPath must end with a backslash."
#         }

#         Write-EnhancedLog -Message "TaskPath '$TaskPath' is correctly formatted." -Level "INFO"
#     }

#     End {
#         Write-EnhancedLog -Message "Exiting Validate-TaskPath function" -Level "Notice"
#     }
# }


# function Unregister-ScheduledTaskWithLogging {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $false)]
#         [string]$TaskName,

#         [Parameter(Mandatory = $false)]
#         [string]$TaskPath
#     )

#     Begin {
#         Write-EnhancedLog -Message "Starting Unregister-ScheduledTaskWithLogging function" -Level "Notice"
#         Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

#         # Validate TaskPath format
#         if ($TaskPath) {
#             Validate-TaskPath -TaskPath $TaskPath
#         }
#     }

#     Process {
#         try {
#             $retries = 3
#             $delayBetweenRetries = 2 # seconds
            
#             while ($retries -gt 0) {
#                 if ($TaskPath -and $TaskName) {
#                     Write-EnhancedLog -Message "Checking if task '$TaskName' in path '$TaskPath' exists before attempting to unregister." -Level "INFO"
#                     $taskExistsBefore = Test-Path "TaskScheduler::\$TaskPath\$TaskName"
                    
#                     if ($taskExistsBefore) {
#                         Write-EnhancedLog -Message "Task '$TaskPath\$TaskName' found. Proceeding to unregister." -Level "INFO"
#                         Unregister-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -Confirm:$false -ErrorAction Stop
#                         Write-EnhancedLog -Message "Unregister-ScheduledTask done for task: $TaskPath\$TaskName" -Level "INFO"
#                     } else {
#                         Write-EnhancedLog -Message "Task '$TaskPath\$TaskName' not found. No action taken." -Level "INFO"
#                     }
#                 } elseif ($TaskPath) {
#                     Write-EnhancedLog -Message "Checking for tasks in path '$TaskPath' before attempting to unregister." -Level "INFO"
#                     try {
#                         $tasks = Get-ScheduledTask -TaskPath $TaskPath -ErrorAction Stop
#                     } catch {
#                         if ($_.Exception.Message -match "No MSFT_ScheduledTask objects found") {
#                             Write-EnhancedLog -Message "No tasks found in path '$TaskPath'. No action taken." -Level "WARNING"
#                         } else {
#                             Write-EnhancedLog -Message "An error occurred while retrieving tasks in path '$TaskPath'. Error: $($_.Exception.Message)" -Level "ERROR"
#                             throw
#                         }
#                         return
#                     }
                    
#                     if ($tasks.Count -gt 0) {
#                         foreach ($task in $tasks) {
#                             Write-EnhancedLog -Message "Task '$($task.TaskName)' found in path '$TaskPath'. Proceeding to unregister." -Level "INFO"
#                             Unregister-ScheduledTask -TaskPath $TaskPath -TaskName $task.TaskName -Confirm:$false -ErrorAction Stop
#                             Write-EnhancedLog -Message "Unregister-ScheduledTask done for task: $($task.TaskName)" -Level "INFO"
#                         }
#                     } else {
#                         Write-EnhancedLog -Message "No tasks found in path '$TaskPath'. No action taken." -Level "INFO"
#                     }
#                 } elseif ($TaskName) {
#                     Write-EnhancedLog -Message "Checking if task '$TaskName' exists before attempting to unregister." -Level "INFO"
#                     $taskExistsBefore = Get-ScheduledTask | Where-Object { $_.TaskName -eq $TaskName }
                    
#                     if ($taskExistsBefore) {
#                         Write-EnhancedLog -Message "Task '$TaskName' found. Proceeding to unregister." -Level "INFO"
#                         Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
#                         Write-EnhancedLog -Message "Unregister-ScheduledTask done for task: $TaskName" -Level "INFO"
#                     } else {
#                         Write-EnhancedLog -Message "Task '$TaskName' not found. No action taken." -Level "INFO"
#                     }
#                 } else {
#                     Write-EnhancedLog -Message "Neither TaskPath nor TaskName was provided. No action taken." -Level "WARNING"
#                 }
                
#                 # Re-check to ensure the task is unregistered
#                 $taskExistsAfter = Test-Path "TaskScheduler::\$TaskPath\$TaskName"
#                 if (-not $taskExistsAfter) {
#                     Write-EnhancedLog -Message "Confirmed task '$TaskPath\$TaskName' has been unregistered." -Level "INFO"
#                     break
#                 } else {
#                     Write-EnhancedLog -Message "Task '$TaskPath\$TaskName' still exists after unregistration attempt. Retrying..." -Level "WARNING"
#                     Start-Sleep -Seconds $delayBetweenRetries
#                     $retries--
#                 }
#             }

#             if ($retries -eq 0 -and $taskExistsAfter) {
#                 Write-EnhancedLog -Message "Failed to unregister task '$TaskPath\$TaskName' after multiple attempts." -Level "ERROR"
#                 throw "Failed to unregister task '$TaskPath\$TaskName'."
#             }
#         } catch {
#             Write-EnhancedLog -Message "Error during Unregister-ScheduledTask. Error: $($_.Exception.Message)" -Level "ERROR"
#             Handle-Error -ErrorRecord $_
#         }
#     }

#     End {
#         Write-EnhancedLog -Message "Exiting Unregister-ScheduledTaskWithLogging function" -Level "Notice"
#     }
# }
