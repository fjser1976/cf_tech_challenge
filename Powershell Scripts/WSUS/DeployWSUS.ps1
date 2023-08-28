<#
--------------
WSUS Installer v2
Last nodified 2/19/2020
--------------
by Schloendorn

Based on script downloaded from Internet by Trevor Jones

This script installs and configures WSUS on a Windows 2019 server.
Options are configurable in the WSUSConfig.xml file
The script will do an initial configuration of WSUS including:
  > installs SQL CLR Types and Report Viewer (required for reporting in WSUS)
  > Installs WSUS role and performs initial configuration
  > Set sync from Microsoft Update
  > Set update language to English
  > Set servers to directly download updates from MS or from WSUS server (configure in XML)
  > Set the WSUS Products to Sync (configure in XML)
  > Set the WSUS Categories to Sync (configure in XML)
  > Enable scheduled WSUS sync at midnight every night

  See xml file that accompanies script for additional options

//Prereqs//
- Powershell 4.0
- Run as administrator
- Internet connectivity
- Windows Server 2019 (not tested on earlier versions)
- Configure options in XML before executing
- Verify the location specified in xml file to store updates is accessible
#>



#Configuration

#Read in Config File
$config = ([xml](Get-Content WSUSConfig.xml)).root

# Do you want to download and install MS Report Viewer 2012 Runtime (required for WSUS Reports)?
    $RepViewer = [System.Convert]::ToBoolean($config.Install.ReportViewer)
# WSUS Installation Type.  Enter "WID" (for WIndows Internal Database), "SQLExpress" (to download and install a local SQLExpress), or "SQLRemote" (for an existing SQL Instance).  
    $WSUSType = $config.install.DBType
# Location to store WSUS Updates (will be created if doesn't exist)
    $WSUSDir = $config.install.UpdateStorageLocation
# Temporary location for installation files (will be created if doesn't exist)
    $TempDir = "C:\temp"


# Do you want to configure WSUS (equivalent of WSUS Configuration Wizard, plus some additional options)?  If $false, no further variables apply.
# You can customise the configurations, such as Products and Classifications etc, in the "Begin Initial Configuration of WSUS" section of the script.
    $ConfigureWSUS = [System.Convert]::ToBoolean($config.WSUSConfig.AutoConfigureWSUS)

# Do you want to configure and enable the Default Approval Rule?
    $DefaultApproval = [System.Convert]::ToBoolean($config.WSUSConfig.DefaultApproval)
# Do you want to run the Default Approval Rule after configuring?
    $RunDefaultRule = [System.Convert]::ToBoolean($config.WSUSConfig.RunDefault)



#####################
## Start of Script ##
#####################

$ErrorActionPreference = "Inquire"
cls
write-host ' ' 
write-host ' ' 
write-host ' ' 
write-host ' ' 
write-host ' ' 
write-host ' ' 
write-host '#######################' 
write-host '## WSUS INSTALLATION ##'
write-host '#######################' 
write-host ' ' 
write-host ' '



# Create temp folder for downloads if doesn't exist

if(Test-Path $TempDir)
{
$Tempfolder = "Yes"}
else{$Tempfolder = "No"}

If ($Tempfolder -eq "No")
{
New-Item $TempDir -type directory | Out-null
}





# Download MS Report Viewer 2012 and CRL Types for WSUS reports

if ($RepViewer -eq $True)
{
write-host "Downloading CRLType for SQL 2012 (Required by Report Viewer)...please wait"
$URL = $config.Install.CRLTypesURL
Start-BitsTransfer $URL $TempDir -RetryInterval 60 -RetryTimeout 180 -ErrorVariable err
if ($err)
{
write-host "Microsoft CRL Types for SQL 2012 could not be downloaded!" -ForegroundColor Red
write-host 'Please download and install it manually to use WSUS Reports.' -ForegroundColor Red
write-host 'Continuing anyway...' -ForegroundColor Magenta
}
write-host "Downloading Microsoft Report Viewer 2012 Runtime...please wait"
$URL = $config.Install.ReportViewerURL
Start-BitsTransfer $URL $TempDir -RetryInterval 60 -RetryTimeout 180 -ErrorVariable err
if ($err)
{
write-host "Microsoft Report Viewer 2012 Runtime could not be downloaded!" -ForegroundColor Red
write-host 'Please download and install it manually to use WSUS Reports.' -ForegroundColor Red
write-host 'Continuing anyway...' -ForegroundColor Magenta
}


# Install MS CLR Types for SQL 2012

write-host 'Installing Microsoft CLR Types for SQL 2012...'
$arguments = "/i $TempDir\SQLSysClrTypes.msi /q"
$setup=Start-Process msiexec -ArgumentList $arguments -Wait -PassThru
if ($setup.exitcode -eq 0)
{
write-host "Successfully installed" 
}
else
{
write-host 'Microsoft CLR Types for SQL 2012 Did not install correctly.' -ForegroundColor Red
write-host 'Please download and install it manually to use WSUS Reports.' -ForegroundColor Red
write-host 'Continuing anyway...' -ForegroundColor Magenta
}

# Install MS Report Viewer 2012 Runtime

write-host 'Installing Microsoft Report Viewer 2012 Runtime...'
$arguments = "/i $TempDir\ReportViewer.msi /q"
$setup=Start-Process msiexec -verb RunAs -ArgumentList $arguments -Wait -PassThru
if ($setup.exitcode -eq 0)
{
write-host "Successfully installed" 
}
else
{
write-host 'Microsoft Report Viewer 2012 Runtime did not install correctly.' -ForegroundColor Red
write-host 'Please download and install it manually to use WSUS Reports.' -ForegroundColor Red
write-host 'Continuing anyway...' -ForegroundColor Magenta
}
}



# Install WSUS (WSUS Services, SQL Database, Management tools)

if ($WSUSType -eq 'WID')
{
write-host 'Installing WSUS for WID (Windows Internal Database)'
Install-WindowsFeature -Name UpdateServices -IncludeManagementTools
}

## Create WSUS Updates folder if doesn't exist

if(Test-Path $WSUSDir)
{
$WSUSfolder = "Yes"}
else{$WSUSfolder = "No"}

If ($WSUSfolder -eq "No")
{
New-Item $WSUSDir -type directory | Out-null
}



# Run WSUS Post-Configuration

if ($WSUSType -eq 'WID')
{
sl "C:\Program Files\Update Services\Tools"
.\wsusutil.exe postinstall CONTENT_DIR=$WSUSDir
}

<#
if ($WSUSType -eq 'SQLExpress') 
{
sl "C:\Program Files\Update Services\Tools"
.\wsusutil.exe postinstall SQL_INSTANCE_NAME="%COMPUTERNAME%\SQLEXPRESS" CONTENT_DIR=$WSUSDir
}
if ($WSUSType -eq 'SQLRemote') 
{
sl "C:\Program Files\Update Services\Tools"
.\wsusutil.exe postinstall SQL_INSTANCE_NAME=$SQLInstance CONTENT_DIR=$WSUSDir
}
#>


# Begin Initial Configuration of WSUS

if ($ConfigureWSUS -eq $True)
{
# Get WSUS Server Object
$wsus = Get-WSUSServer

# Connect to WSUS server configuration
$wsusConfig = $wsus.GetConfiguration()


# Set to download updates from Microsoft Updates
Set-WsusServerSynchronization –SyncFromMU

# Set Various WSUS settings
$wsusConfig.AllUpdateLanguagesEnabled = $false           
$wsusConfig.SetEnabledUpdateLanguages("en") 
$wsusConfig.TargetingMode = $config.WSUSConfig.TargetingMode
$wsusConfig.HostBinariesOnMicrosoftUpdate = $config.WSUSConfig.DirectFromMS
$wsusConfig.Save()

#Create Groups
Write-Host "Creating WSUS Target Groups"
foreach ($item in $config.WSUSConfig.TargetGroups.Group)
{
    Write-Host "Creating Group $item"
    $wsus.CreateComputerTargetGroup($item)
}
#create default parent group
Write-host "Creating Default Group"
$wsus.CreateComputerTargetGroup("Default")
#get parent group
$group = $wsus.GetComputerTargetGroups() | ? {$_.Name -eq "Default"}
#create sub-groups if provided
foreach ($subitem in $config.WSUSConfig.TargetGroups.SubGroups.SubGroup) {
write-host "Creating Sub-Group $subitem"
$wsus.CreateComputerTargetGroup($subitem,$group)
}

Write-Host "Target Group Creation Complete"


# Get WSUS Subscription and perform initial synchronization to get latest categories
$subscription = $wsus.GetSubscription()
$subscription.StartSynchronizationForCategoryOnly()
write-host 'Beginning first WSUS Sync to get available Products etc' -ForegroundColor Magenta
write-host 'Will take some time to complete (up to 30 mins)'
Start-Sleep -Seconds 60 # Wait for sync to start before monitoring 
while ($subscription.GetSynchronizationProgress().ProcessedItems -ne $subscription.GetSynchronizationProgress().TotalItems) {            
    Write-Progress -PercentComplete (            
    $subscription.GetSynchronizationProgress().ProcessedItems*100/($subscription.GetSynchronizationProgress().TotalItems)            
    ) -Activity "WSUS Sync Progress"            
} 
Write-Host "Sync is done." -ForegroundColor Green


# Configure the Platforms that we want WSUS to receive updates
Write-host "Configuring platforms that will receive updates..."
#By default - all windows products are enabeld, we will disable then re-enable specific ones
Get-WsusProduct | Where-Object -FilterScript {$_.product.title -Eq "Windows"} | Set-WsusProduct -Disable
foreach ($item in $config.WSUSConfig.Products.ProductEntry) 
    {
       Write-Host "Setting Platform $item for updates"
       Get-WsusProduct | Where-Object -FilterScript {$_.product.title -Eq $item} | Set-WsusProduct 
    }
Write-Host "Done Setting Platforms"
# Configure the Classifications that we want WSUS to receive updates
Write-Host "Configuring Classifications of Updatest to receive..."
foreach ($item in $config.WSUSConfig.Classifications.ClassEntry) 
    {
       Write-Host "Setting Classification $item for updates"
        Get-Wsusclassification | Where-Object -FilterScript {$_.classification.title -Eq $item} | Set-WsusClassification
    }
Write-Host "Done Setting Classifications"

<#--
# Prompt to check products are set correctly
write-host 'Before continuing, please open the WSUS Console, cancel the WSUS Configuration Wizard,' - -ForegroundColor Red
write-host 'Go to Options > Products and Classifications, and check that the Products are set correctly.' - -ForegroundColor Red
write-host 'Pausing script' -ForegroundColor Yellow
$Shell = New-Object -ComObject "WScript.Shell"
$Button = $Shell.Popup("Click OK to continue.", 0, "Script Paused", 0) # Using Pop-up in case script is running in ISE
#>

#Increase memory size of iis pool to avoid server crashes
Import-Module WebAdministration
Write-Host "Increasing IIS Pool Size"
$NewPrivateMemoryLimit = 8388608
$ApplicationPoolsPath = "/system.applicationHost/applicationPools"
$ApplicationPools = Get-WebConfiguration $applicationPoolsPath
    foreach ($AppPool in $ApplicationPools.Collection) {
     if ($AppPool.name -eq 'WsusPool') {
      $AppPoolPath = "$ApplicationPoolsPath/add[@name='$($AppPool.Name)']"
      $CurrentPrivateMemoryLimit = (Get-WebConfiguration "$AppPoolPath/recycling/periodicRestart/@privateMemory").Value
            "Private Memory Limit for $($AppPool.name) is currently set to: $($CurrentPrivateMemoryLimit/1000) MB"
            Set-WebConfiguration "$AppPoolPath/recycling/periodicRestart/@privateMemory" -Value $NewPrivateMemoryLimit
            "New Private Memory Limit for $($AppPool.name) is: $($NewPrivateMemoryLimit/1000) MB"
            Restart-WebAppPool -Name $($AppPool.name)
            "Restarted the $($AppPool.name) Application Pool to apply changes"
            }
     }
# Cleaning Up TempDir

write-host 'Cleaning temp directory'
if (Test-Path $TempDir\ReportViewer.msi)
{Remove-Item $TempDir\ReportViewer.msi -Force}
if (Test-Path $TempDir\SQLSysClrTypes.msi)
{Remove-Item $TempDir\SQLSysClrTypes.msi -Force}
#if (Test-Path $TempDir\SQLEXPRWT_x64_ENU.exe)
#{Remove-Item $TempDir\SQLEXPRWT_x64_ENU.exe -Force}


# Configure Synchronizations
write-host 'Enabling WSUS Automatic Synchronization'
$subscription.SynchronizeAutomatically=$true

# Set synchronization scheduled for midnight each night
$subscription.SynchronizeAutomaticallyTimeOfDay= (New-TimeSpan -Hours 0)
$subscription.NumberOfSynchronizationsPerDay=1
$subscription.Save()

# Kick off a synchronization
$subscription.StartSynchronization()



# Monitor Progress of Synchronization

write-host 'Beginning full WSUS Sync, will take some time' -ForegroundColor Magenta  
write-host 'You can safely abort the script at this point and the synch will still continue in background' -ForegroundColor Magenta 
Start-Sleep -Seconds 60 # Wait for sync to start before monitoring      
while ($subscription.GetSynchronizationProgress().ProcessedItems -ne $subscription.GetSynchronizationProgress().TotalItems) {            
    Write-Progress -PercentComplete (            
    $subscription.GetSynchronizationProgress().ProcessedItems*100/($subscription.GetSynchronizationProgress().TotalItems)            
    ) -Activity "WSUS Sync Progress"            
}  
Write-Host "Sync is done." -ForegroundColor Green


}


write-host 'WSUS log files can be found here: %ProgramFiles%\Update Services\LogFiles'
write-host 'Done!' -foregroundcolor Green



