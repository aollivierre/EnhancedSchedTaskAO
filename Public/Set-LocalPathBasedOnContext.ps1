function Set-LocalPathBasedOnContext {
    Write-EnhancedLog -Message "Checking running context..." -Level "INFO"
    if (Test-RunningAsSystem) {
        Write-EnhancedLog -Message "Running as system, setting path to Program Files" -Level "INFO"
        # return "$ENV:Programfiles\_MEM"
        return "C:\_MEM"
    }
    else {
        Write-EnhancedLog -Message "Running as user, setting path to Local AppData" -Level "INFO"
        return "$ENV:LOCALAPPDATA\_MEM"
    }
}