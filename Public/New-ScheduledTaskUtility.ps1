function New-ScheduledTaskUtility {
    [CmdletBinding()]
    param (
        ### General Task Settings ###
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $true)]
        [string]$TaskDescription,

        ### Script Settings (Always Used) ###
        [Parameter(Mandatory = $true)]
        [string]$ScriptDirectory,  # Always required, so no need for ParameterSetName

        [Parameter(Mandatory = $true)]
        [string]$ScriptName,  # Always required, so no need for ParameterSetName

        ### Task Arguments and PowerShell Path (PowerShell Execution Only) ###
        [Parameter(Mandatory = $false, ParameterSetName = 'PowerShellDirect')]
        [string]$TaskArguments,

        [Parameter(Mandatory = $false, ParameterSetName = 'PowerShellDirect')]
        [string]$PowerShellPath,

        ### Task Principal (Optional) ###
        [Parameter(Mandatory = $false)]
        [string]$TaskPrincipalGroupId,

        ### VBS Hidden Execution ###
        [Parameter(Mandatory = $true, ParameterSetName = 'VBScriptHidden')]
        [switch]$HideWithVBS,

        [Parameter(Mandatory = $true, ParameterSetName = 'VBScriptHidden')]
        [string]$VbsFileName = "run-ps-hidden.vbs",

        ### Task Trigger (Optional) ###
        [Parameter(Mandatory = $true)]
        [switch]$AtLogOn,

        ### Task Repetition (Optional) ###
        [Parameter(Mandatory = $false)]
        [switch]$EnableRepetition,

        [Parameter(Mandatory = $false)]
        [string]$TaskRepetitionDuration = "P1D",

        [Parameter(Mandatory = $false)]
        [string]$TaskRepetitionInterval = "PT30M"
    )

    Begin {
        Write-EnhancedLog -Message "Starting New-ScheduledTaskUtility function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Unregister the task if it exists
            Unregister-ScheduledTaskWithLogging -TaskName $TaskName

            # Prepare the script path and arguments
            $scriptFullPath = Join-Path -Path $ScriptDirectory -ChildPath $ScriptName

            # Check if HideWithVBS is set, create VBScript for hidden execution
            if ($HideWithVBS) {
                Write-EnhancedLog -Message "Creating VBScript for hidden execution" -Level "INFO"
                $vbsScriptPath = Create-VBShiddenPS -Path_local $ScriptDirectory -FileName $VbsFileName

                # Wait-Debugger

                # Set the task action to use wscript.exe with the VBScript and PowerShell script as arguments
                $arguments = "`"$vbsScriptPath`" `"$scriptFullPath`""
                $actionParams = @{
                    Execute  = "C:\Windows\System32\wscript.exe"
                    Argument = $arguments
                }

                # Wait-Debugger
            }
            else {
                # Regular execution using PowerShell
                $arguments = $TaskArguments.Replace("{ScriptPath}", $scriptFullPath)
                $actionParams = @{
                    Execute  = $PowerShellPath
                    Argument = $arguments
                }
            }

            $action = New-ScheduledTaskAction @actionParams

            # Set up the trigger
            $triggerParams = @{
                AtLogOn = $AtLogOn
            }
            $trigger = New-ScheduledTaskTrigger @triggerParams

            # Determine whether to use GroupId or Current Logged-in User
            if ($UseCurrentUser) {
                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                $principalParams = @{
                    UserId = $currentUser
                }
                Write-EnhancedLog -Message "Using current logged-in user: $currentUser" -Level "INFO"
            }
            else {
                $principalParams = @{
                    GroupId = $TaskPrincipalGroupId
                }
                Write-EnhancedLog -Message "Using group ID: $TaskPrincipalGroupId" -Level "INFO"
            }

            $principal = New-ScheduledTaskPrincipal @principalParams

            # Register the task with the repetition settings if enabled
            $registerTaskParams = @{
                Principal   = $principal
                Action      = $action
                Trigger     = $trigger
                TaskName    = $TaskName
                Description = $TaskDescription
                TaskPath    = $TaskPath
            }

            # Register the task
            $Task = Register-ScheduledTask @registerTaskParams

            # Set task repetition parameters only if the EnableRepetition switch is used
            if ($EnableRepetition) {
                Write-EnhancedLog -Message "Setting task repetition with duration $TaskRepetitionDuration and interval $TaskRepetitionInterval" -Level "INFO"
                $Task.Triggers.Repetition.Duration = $TaskRepetitionDuration
                $Task.Triggers.Repetition.Interval = $TaskRepetitionInterval
                $Task | Set-ScheduledTask
            }
            else {
                Write-EnhancedLog -Message "Task repetition not enabled." -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while creating the OneDrive sync status task: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting New-ScheduledTaskUtility function" -Level "Notice"
    }
}











# $CreateOneDriveSyncUtilStatusTask = @{
#     TaskPath               = "AAD Migration"
#     TaskName               = "AADM Get OneDrive Sync Status"
#     ScriptDirectory        = "C:\ProgramData\AADMigration\Scripts"
#     ScriptName             = "Check-OneDriveSyncStatus.ps1"
#     TaskArguments          = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -file `"{ScriptPath}`""
#     TaskRepetitionDuration = "P1D"
#     TaskRepetitionInterval = "PT30M"
#     PowerShellPath         = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
#     TaskDescription        = "Get current OneDrive Sync Status and write to event log"
#     AtLogOn                = $true
#     UseCurrentUser         = $true  # Specify to use the current user
# }

# New-ScheduledTaskUtility @CreateOneDriveSyncUtilStatusTask
