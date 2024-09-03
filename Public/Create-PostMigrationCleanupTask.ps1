function Create-PostMigrationCleanupTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptDirectory,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskArguments,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskPrincipalUserId,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskRunLevel,
        
        [Parameter(Mandatory = $true)]
        [string]$PowerShellPath,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskDescription,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskTriggerType,
        
        [Parameter(Mandatory = $false)]
        [string]$Delay  # Optional delay
    )

    Begin {
        Write-EnhancedLog -Message "Starting Create-PostMigrationCleanupTask function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Validate if the task already exists before creation
            if (Validate-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName) {
                Write-EnhancedLog -Message "Task '$TaskName' found before creation. It will be unregistered first." -Level "WARNING"
                Unregister-ScheduledTaskWithLogging -TaskName $TaskName
            }

            # Replace placeholder with the actual script path
            $arguments = $TaskArguments.Replace("{ScriptPath}", "$ScriptDirectory\$ScriptName")

            # Create the scheduled task action
            $actionParams = @{
                Execute  = $PowerShellPath
                Argument = $arguments
            }
            $action = New-ScheduledTaskAction @actionParams

            # Create the scheduled task trigger based on the type provided
            $triggerParams = @{
                $TaskTriggerType = $true
            }
            $trigger = New-ScheduledTaskTrigger @triggerParams

            # Apply the delay if provided
            if ($PSBoundParameters.ContainsKey('Delay')) {
                $trigger.Delay = $Delay
                Write-EnhancedLog -Message "Setting Delay: $Delay" -Level "INFO"
            }

            # Create the scheduled task principal
            $principalParams = @{
                UserId   = $TaskPrincipalUserId
                RunLevel = $TaskRunLevel
            }
            $principal = New-ScheduledTaskPrincipal @principalParams

            # Register the scheduled task
            $registerTaskParams = @{
                Principal   = $principal
                Action      = $action
                Trigger     = $trigger
                TaskName    = $TaskName
                Description = $TaskDescription
                TaskPath    = $TaskPath
            }
            $Task = Register-ScheduledTask @registerTaskParams

            Write-EnhancedLog -Message "Task '$TaskName' created successfully at '$TaskPath'." -Level "INFO"

            # Validate the task after creation
            if (Validate-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName) {
                Write-EnhancedLog -Message "Task '$TaskName' created and validated successfully." -Level "INFO"
            } else {
                Write-EnhancedLog -Message "Task '$TaskName' creation failed validation." -Level "ERROR"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Create-PostMigrationCleanupTask function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Create-PostMigrationCleanupTask function" -Level "Notice"
    }
}

# # Example usage with splatting
# $CreatePostMigrationCleanupTaskParams = @{
#     TaskPath            = "AAD Migration"
#     TaskName            = "Run Post-migration cleanup"
#     ScriptDirectory     = "C:\ProgramData\AADMigration\Scripts"
#     ScriptName          = "PostRunOnce3.ps1"
#     TaskArguments       = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"{ScriptPath}`""
#     TaskPrincipalUserId = "NT AUTHORITY\SYSTEM"
#     TaskRunLevel        = "Highest"
#     PowerShellPath      = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
#     TaskDescription     = "Run post AAD Migration cleanup"
#     TaskTriggerType     = "AtLogOn"  # The trigger type can be passed as a parameter now
#     Delay               = "PT1M"  # Optional delay before starting
# }

# Create-PostMigrationCleanupTask @CreatePostMigrationCleanupTaskParams