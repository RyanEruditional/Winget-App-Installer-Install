#$ResolveWingetPath = @(Resolve-Path 'C:\Program Files\WindowsApps\*\winget.exe')[0]; Write-Host "$ResolveWingetPath"; & $ResolveWingetPath --version
#Declares the function 'Invoke-Download'
Function Invoke-Download {
    param (
        [string]$Url,
        [string]$Path
    )
    try {
        Write-Host "Invoking Download"
        Write-Host "Downloading $Url TO (->) $Path"
        $webClient = New-Object Net.WebClient
        $webClient.DownloadFile($Url, $Path)
    }
    catch {
        Throw "Failed to Invoke Download for Winget Installation"
    }
}

Function Install-WingetWindowsPackageManager {
    param (
        [string]$WingetDownloadPath,
        [string]$VClibs64DownloadPath,
        [string]$XmalPath
    )

    Write-Host "XmalPath is: $XmalPath"
    Write-Host "VClibs64DownloadPath is: $VClibs64DownloadPath"
    Write-Host "WingetDownloadPath is: $WingetDownloadPath"

    try {
        Write-Host "Attempting to Install Winget-WindowsPackageManager"
        Add-AppxProvisionedPackage -Online -PackagePath $WingetDownloadPath -DependencyPackagePath $VClibs64DownloadPath,$XmalPath -SkipLicense
        Start-Sleep 5
    } catch {
        Write-Host -IsError "Failed to install AppxProvisionedPackage: $WingetDownloadPath"
        Throw
    }
}

Function Test-Winget {
    try {
        try {
            $ResolveWingetPath = @(Resolve-Path 'C:\Program Files\WindowsApps\*\winget.exe')[-1] #Pick last item in array (most recent)
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

        $Reinstall = 0
        $Check = 0

        while ($true) {
            try {
                Write-Host "Attempting to get Winget Version"
                $ResolveWingetVersion = ((& $ResolveWingetPath --version).ToString() -Replace '[^0-9\.]')
                if ($ResolveWingetVersion -as [version]) {
                    $InstalledWingetVersion = [version]$ResolveWingetVersion
                    Write-Host "Current Winget Version is: $InstalledWingetVersion"
                    $RequiredWingetVersion = [version]"1.4.3531"
                }
                Write-Host "Current Winget Version is: $ResolveWingetVersion"
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
            }
            catch {
                Write-Host "Unable to get Winget Path. Presenting error message:"
                Write-Host "[$($_.Exception.Message)]"
                Write-Host "Setting ResolveWingetPath to null"
                $ResolveWingetPath = $null
            }
            
            Write-Host "Checking Condition"
            if (($InstalledWingetVersion -lt $RequiredWingetVersion) -or (-not $ResolveWingetVersion)) {
                Write-Host "Unable to obtain Winget Version"
                $Check = $Check + 1
                Write-Host "Amounts of times checked: $Check"
                Start-Sleep 1
            } else {
                Write-Host "Winget Version has been obtained"
                Write-Host "Winget Version is $ResolveWingetVersion"
                return $Reinstall
            }
            if ($check -eq 120) {
                Write-Host "Maximum of Checks has been reached. ($Check), Attempting reinstall of Winget"
                $Reinstall = 1
                return $Reinstall
            }
        }
    } catch {
        Write-Host "There was a problem initiating Winget commands after Winget path was resolved."
        Write-Host "[$($_.Exception.Message)]"
    
    }
}

Start-Transcript -Path "C:\Eruditional-IT\Intune\Winget-AppInstaller\Winget-WindowsPackageManager_Install.log" -Append
Write-Host "Starting Transcript for Winget-WindowsPackageManager Installation"

#Declare Variables for Download Files

$downloadFolder = ('C:\Eruditional-IT\Intune\Winget-AppInstaller')
$WingetURL = "https://aka.ms/getwinget"
$WingetFileName = ("Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle")
$WingetDownloadPath = ('{0}\{1}' -f $downloadFolder, $WingetFileName)

$VClibs64URL ="https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
$VClibs64FileName = ("Microsoft.VCLibs.x64.14.00.Desktop.appx")
$VClibs64DownloadPath = ('{0}\{1}' -f $downloadFolder, $VClibs64FileName)

$XmalURL ="http://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3"
$XmalFileName = ("microsoft.ui.xaml.2.7.3.zip")
$XmalDownloadPath = ('{0}\{1}' -f $downloadFolder, $XmalFileName)



#Downloading Files
Write-Host "Attempting to download required files"
Invoke-Download -Url $WingetURL -Path $WingetDownloadPath
Invoke-Download -Url $VClibs64URL -Path $VClibs64DownloadPath
Invoke-Download -Url $XmalURL -Path $XmalDownloadPath

Expand-Archive -Path $XmalDownloadPath -DestinationPath "C:\Eruditional-IT\Intune\Winget-AppInstaller\MicrosoftUIXaml"
$ExtractedXMALPath = "C:\Eruditional-IT\Intune\Winget-AppInstaller\MicrosoftUIXaml\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx"

Write-Host "Running Function: Install-WingetWindowsPackageManager"
Install-WingetWindowsPackageManager -WingetDownloadPath $WingetDownloadPath -VClibs64DownloadPath $VClibs64DownloadPath -XmalPath $ExtractedXMALPath

Write-Host "Running Function: Test-Winget"
$WingetReinstall = Test-Winget
Write-Host "Reinstall value is: $WingetReinstall"

While ($WingetReinstall -eq 1) {
    Write-Host "Attempting Reinstall"
    Install-WingetWindowsPackageManager -WingetDownloadPath $WingetDownloadPath -VClibs64DownloadPath $VClibs64DownloadPath -XmalPath $ExtractedXMALPath
    Write-Host "Testing Winget"
    $WingetReinstall = Test-Winget
}

Write-Host "Winget (App Installer) has been successfully installed."
