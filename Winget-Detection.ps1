Function Test-Winget {
    try {
        try {
            $ResolveWingetPath = @(Resolve-Path 'C:\Program Files\WindowsApps\*\winget.exe')[-1]
            Write-Host "Winget Path is $ResolveWingetPath"
        }
        catch {
            $ResolveWingetPath = $null
        }

        try {
            $ResolveWingetVersion = & $ResolveWingetPath --version
            Write-Host "Winget Version is: $ResolveWingetVersion"
        }catch{
            $ResolveWingetVersion =$null
        }

        try {
            Write-Host "Attempting to get Winget Version"
            $ResolveWingetVersion = ((& $ResolveWingetPath --version).ToString() -Replace '[^0-9\.]')
            if ($ResolveWingetVersion -as [version]) {
                $InstalledWingetVersion = [version]$ResolveWingetVersion
                Write-Host "Current Winget Version is: $InstalledWingetVersion"
                $RequiredWingetVersion = [version]"1.4.3531"
            }
        } catch {
            Write-Host "Unable to get Winget Version. Presenting error message:"
            Write-Host "[$($_.Exception.Message)]"
            Write-Host "Setting WingetVersion to null"
            $ResolveWingetVersion = $null  # Set the version to null in case of an error
        }

        try {
            Write-Host "Attempting to get Winget Path"
            $ResolveWingetPath = @(Resolve-Path 'C:\Program Files\WindowsApps\*\winget.exe')[-1]
            Write-Host "Winget Path is $ResolveWingetPath"
        } catch {
            Write-Host "Unable to get Winget Path. Presenting error message:"
            Write-Host "[$($_.Exception.Message)]"
            Write-Host "Setting ResolveWingetPath to null"
            $ResolveWingetPath = $null
        }
            
        Write-Host "Checking Condition"
        if (($InstalledWingetVersion -lt $RequiredWingetVersion) -or (-not $ResolveWingetVersion)) {
            Write-Host "Unable to obtain Winget Version or Resolve Winget Path"
            Write-Host "Exit Code is: 1 (Unsuccessful)"
            exit 1
        } else {
            Write-Host "Winget Path has been resolved."
            Write-Host "Winget Version is $ResolveWingetVersion"
            Write-Host "Exit Code is: 0 (Successful)"
            exit 0
        }
    } catch {
        Write-Host "There was a problem initiating Winget commands after Winget path was resolved."
        Write-Host "[$($_.Exception.Message)]"
        Write-Host "Exit Code is: 1 (Unsuccessful)"
        exit 1
    
    }
}


Start-Transcript -Path "C:\Eruditional-IT\Intune\Winget-AppInstaller\Winget-WindowsPackageManager_Detection.log" -Append
Test-Winget
