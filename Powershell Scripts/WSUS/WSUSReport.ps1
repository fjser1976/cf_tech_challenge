<#
Requires latest version (2.3.2) of poshwsus module avaialble from https://github.com/proxb/PoshWSUS
Version: 3
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Read in Config File
$config = ([xml](Get-Content PatchConfig.xml)).root

#prepare report file
$report = $pwd.ToString() + "\Logs\" + $config.Environment + "_PostPatchReport_{0:MMddyy_HHmm}.log" -f (Get-Date)
new-item -path $report -type file -force

#Import modules used
Import-module updateservices
Import-Module poshwsus

#connect to wsus server
Connect-PSWSUSServer -WsusServer $config.WSUSServer -port $config.WSUSPort -SecureConnection

#Set Update scope to only include updates that have been approved
$Scope = New-PSWSUSUpdateScope -ApprovedStates LatestRevisionApproved
#Get all systems
$TotalSystems = Get-PSWSUSClient
#Get Fully Patched Systems
$FullyPatched = Get-PSWSUSUpdateSummaryPerClient -UpdateScope $Scope | Where-Object {($_.Needed -eq 0) -and ($_.PendingReboot -eq 0) -and ($_.Failed -eq 0)}
#Get Systems Needing Reboot
$NeedingReboot = Get-PSWSUSUpdateSummaryPerClient -UpdateScope $Scope | Where-Object {($_.PendingReboot -gt 0)}
#Get Systems missing patches
$NotFullyPatched = Get-PSWSUSUpdateSummaryPerClient -UpdateScope $Scope | Where-Object {($_.Needed -gt 0) -or ($_.Failed -gt 0)}
#Get systems that have not heartbeated in last 7 days
$now = get-date
$weekago = $now.adddays(-7)
$oddate = $now.adddays($config.OverdueDays)
$StaleSystems = get-pswsusclient | Where-Object {($_.lastsynctime -lt $weekago) -or ($_.lastreportedstatustime -lt $weekago)} 
#Get systems that failed their last synch attempt
$synchErrors = get-pswsusclient |where-object {$_.lastsyncresult -ne "Succeeded"}


#This is a list of all needed Patches including previously approved that are still not installed
$PendingPatches = Get-PSWSUSUpdate -IncludedInstallationState NotInstalled,Failed,Downloaded,InstalledPendingReboot -ApprovedState LatestRevisionApproved
#cmdlet hangs if no pending patches, so check that for that
if($PendingPatches.count -ne 0) {   
    $UpdateSummary = Get-PSWSUSUpdateSummaryPerGroup -GroupName "All Computers" -UpdateObject $PendingPatches 
}else{
    $UpdateSummary=""
}
$OverduePatches = Get-PSWSUSUpdate -IncludedInstallationState NotInstalled,Failed,Downloaded,InstalledPendingReboot -ApprovedState LatestRevisionApproved | where-object {$_.CreationDate -lt $oddate}
if($OverduePatches.count -ne 0) {   
    $OverdueSummary = Get-PSWSUSUpdateSummaryPerGroup -GroupName "All Computers" -UpdateObject $OverduePatches 
}else{
    $OverdueSummary=""
}
#List of computers that are overdue
$compscope = New-PSWSUSComputerScope
$SystemsOverdue = @()
foreach($patch in $OverduePatches) {
    $OverDuehosts = $patch.GetUpdateInstallationInfoPerComputerTarget($compscope) | ?{($_.UpdateInstallationState -eq "NotInstalled") -or ($_.UpdateInstallationState -eq "Downloaded") -or ($_.UpdateInstallationState -eq "PendingReboot") -or ($_.UpdateInstallationState -eq "Failed")} 
    foreach ($thost in $OverDuehosts) {
        $SystemsOverdue += $thost.ComputerName
    }
}
#remove any duplicates
$SystemsOverdue = $SystemsOverdue | select -Unique

#Patches that need to be reviewed (new since last time approve script was ran)
$UnapprovedNeeded = Get-PSWSUSUpdate -IncludedInstallationState NotInstalled -ApprovedState NotApproved

#Statistics
$NeededCount=0
#$UnknownCount=0
$RebootCount=0
$FailedCount=0
$DownloadedCount=0

$UpdateSummary | ForEach-Object {
$NeededCount=$NeededCount+$_.Needed
$FailedCount=$FailedCount+$_.Failed
$DownloadedCount=$DownloadedCount+$_.Downloaded
$RebootCount=$RebootCount+$_.PendingReboot
#$UnknownCount=$UnknownCount+$_.Unknown
}

$ODTotal=0
$OverdueSummary | ForEach-Object {
    $ODTotal=$ODTotal+$_.Needed+$_.Failed
}

#Main work is done - from here on out its all report generation

$SummaryTitleNew = "Server Summary"
$SummaryTitleActive = "Current Patch Posture (Approved Patches - All Servers)" 
$SummaryTitleNew | Out-File $report -Append
$Spacer = "-------" 
$Spacer | Out-File $report -Append
$TotalSystemsOut = "Total Systems: " + $TotalSystems.Count.ToString()
$TotalSystemsOut | Out-File $report -Append
$FullyPatchedOut = "Systems Fully Patched: " + $FullyPatched.count.ToString() 
$FullyPatchedOut | Out-File $report -Append
$NotFullyPatchedOut = "Systems Missing Approved Updates: " + $NotFullyPatched.count.ToString() 
$NotFullyPatchedOut | Out-File $report -Append
$OverduePatchedOut = "Systems with Overdue Updates: " + $SystemsOverdue.count.ToString() 
$OverduePatchedOut | Out-File $report -Append
$NeedingRebootOut = "Systems Needing a Reboot: " + $NeedingReboot.count.ToString() 
$NeedingRebootOut | Out-File $report -Append
$StaleSystemsOut = "Systems not reporting in 7 days: " + $StaleSystems.count.ToString() 
$StaleSystemsOut | Out-File $report -Append
$SynchErrorsOut = "Systems with Synch Errors: " + $SynchErrors.count.ToString() 
$SynchErrorsOut | Out-File $report -Append

"`r`n" | Out-File $report -Append
$SummaryTitleActive |Out-File $report -Append
$Spacer | Out-File $report -Append
$TotalNeeded = "Total Needed Patches: " + $NeededCount 
$TotalNeeded | Out-File $report -Append
$TotalOD = "Total Patches overdue: " + $ODTotal
$TotalFailed = "Total Failed Patches: " + $FailedCount 
$TotalFailed | Out-File $report -Append
$TotalDownloaded = "Total Downloaded Patches (pending install): " + $DownloadedCount 
$TotalDownloaded | Out-File $report -Append
$TotalPendingReboots = "Total Patches pending reboots: " + $RebootCount 
$TotalPendingReboots| Out-File $report -Append
$Unapproved = "Patches yet to be reviewed for approval: " + $UnapprovedNeeded.count.ToString() 
$Unapproved| Out-File $report -Append
#$TotalUnknown = "Total Unknown count: " + $UnknownCount 
#$TotalUnknown | Out-File $report -Append
"`r`n`n" | Out-File $report -Append

#Output Servers Overdue for patching
"Folowing servers have overdue patches: " | Out-File $report -append #Updating the log file
"-----------------------" | Out-File $report -append #Updating the log file
$SystemsOverdue | Format-Table -Wrap -AutoSize | Out-String -width 4096 |Out-File $report -append

#Output Servers not fully patched
"Folowing servers are not fully patched: " | Out-File $report -append #Updating the log file
"-----------------------" | Out-File $report -append #Updating the log file
$NotFullyPatched | Select Computer, Needed, Failed, PendingReboot | Sort-Object Needed | Format-Table -Wrap -AutoSize | Out-String -width 4096 |Out-File $report -append
#Output Servers needing reboot
"Folowing servers need a reboot to complete patching: " | Out-File $report -append #Updating the log file
"-----------------------" | Out-File $report -append #Updating the log file
$NeedingReboot | Select Computer, Needed, Failed, PendingReboot | Format-Table -Wrap -AutoSize | Out-String -width 4096 |Out-File $report -append

#Output servers that haven't reported in 7 days
"Folowing servers have not reported in last 7 days: " | Out-File $report -append #Updating the log file
"-----------------------" | Out-File $report -append #Updating the log file
$StaleSystems |Select @{Name="Computer";expression={$_.FullDomainName}},@{Name="Last Sync";expression={$_.LastSyncTime}},@{Name="Last Status Report";expression={$_.LastReportedStatusTime}} | Format-Table -Wrap -AutoSize | Out-String -width 4096 |Out-File $report -append
#Output serves with synch errors
"Folowing servers had synch errors : " | Out-File $report -append #Updating the log file
"-----------------------" | Out-File $report -append #Updating the log file
$synchErrors |Select @{Name="Computer";expression={$_.FullDomainName}},@{Name="Last Sync";expression={$_.LastSyncTime}},@{Name="Error";expression={$_.LastSyncResult}} | Format-Table -Wrap -AutoSize | Out-String -width 4096 |Out-File $report -append

#Output overdue patches
"Following Updates are overdue for install on one or more machines: " | Out-File $report -Append
$OverdueSummary |Select @{Name="Update";expression={$_.UpdateTitle}},@{Name="Needed";expression={$_.NeededCount}},@{Name="Failed";expression={$_.FailedCount}},@{Name="Downloaded";expression={$_.DownloadedCount}},@{Name="Needs Reboot";expression={$_.InstalledPendingRebootCount}},@{Name="Unknown";expression={$_.UnknownCount}}| Format-Table -Wrap -AutoSize | Out-String -width 4096 |Out-File $report -append

#Output all pending patches
"Following Updates are pending for install on one or more machines: " | Out-File $report -Append
$UpdateSummary |Select @{Name="Update";expression={$_.UpdateTitle}},@{Name="Needed";expression={$_.NeededCount}},@{Name="Failed";expression={$_.FailedCount}},@{Name="Downloaded";expression={$_.DownloadedCount}},@{Name="Needs Reboot";expression={$_.InstalledPendingRebootCount}},@{Name="Unknown";expression={$_.UnknownCount}}| Format-Table -Wrap -AutoSize | Out-String -width 4096 |Out-File $report -append

#send email
$Attachment = $Report
$Subject = "Daily Patch Report for " + $Config.Environment + " Environment"
 
$BodyEmail = "<h1>Daily Patch report for " + $config.Environment + " Windows Environment</h1><br>" + "<h3>" + $SummaryTitleNew + "</h3><br>" + $TotalSystemsOut + "<br>" + $FullyPatchedOut + "<br>" + $OverduePatchedOut + "<br>" + $NotFullyPatchedOut + "<br>" + $NeedingRebootOut + "<br>" + $StaleSystemsOut+ "<br>" + $SynchErrorsOut + "<br><br>" + "<h3>" + $SummaryTitleActive +"</h3><br>" + $TotalNeeded + "<br>" + $TotalOD + "<br>" + $TotalFailed + "<br>" + $TotalPendingReboots + "<br>" + $TotalDownloaded + "<br>" + $Unapproved + "<br><br>" +  "<h4>Please see attached report for additional details</h4>"

$message = New-Object System.Net.Mail.MailMessage $Config.FromEmail,$Config.ToEmail
$message.subject = $Subject
$Message.IsBodyHtml = $true
$message.Body = $BodyEmail
$message.Attachments.Add($Attachment)
$MailMessage = New-Object Net.Mail.SMTPClient($Config.SMTPServer)
$MailMessage.Send($message)
