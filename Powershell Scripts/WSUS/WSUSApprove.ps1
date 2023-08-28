<#
Requires latest version (2.3.2) of poshwsus module avaialble from https://github.com/proxb/PoshWSUS
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Read in Config File
$config = ([xml](Get-Content PatchConfig.xml)).root
#Test Mode - does whatif for most affecting actions. Set to $false to actually apply changes
$TestMode = [System.Convert]::ToBoolean($config.TestMode)

#prepare report file
$report = $pwd.ToString() + "\Logs\" + $config.Environment + "_PrePatchReport_{0:MMddyy_HHmm}.log" -f (Get-Date)
new-item -path $report -type file -force

#Import modules used
Import-module updateservices
Import-Module poshwsus

#connect to wsus server
Connect-PSWSUSServer -WsusServer $config.WSUSServer -port $config.WSUSPort -SecureConnection

#Last Synch Time
$LastSynch = Get-PSWSUSSyncHistory | Select-object -last 1 
#get all unapproved and needed/failed updates of various types
#Preview Updates
$PreviewUpdates = Get-PSWSUSUpdate -IncludeText "Preview" -ApprovedState NotApproved -IncludedInstallationState NotInstalled,Failed 
#Security Only Updates
$SecOnlyUpdates = Get-PSWSUSUpdate -IncludeText "Security Only" -ApprovedState NotApproved -IncludedInstallationState NotInstalled,Failed 
#Superseded Updates
$SuperSededUpdates = Get-PSWSUSUpdate -IncludedInstallationState NotInstalled,Failed | where {$_.IsSuperseded -eq $true} 

#Decline these updates
$PreviewUpdates | Deny-PSWSUSUpdate -whatif:$TestMode 
$SecOnlyUpdates | Deny-PSWSUSUpdate -whatif:$TestMode 
$SupersededUpdates | Deny-PSWSUSUpdate -whatif:$TestMode 

#Gather new array of updates to approve (everything not declined and pending approval still)
$AllApproved = Get-PSWSUSUpdate -ApprovedState NotApproved -IncludedInstallationState NotInstalled,Failed

#Approve these updates
$Groups = Get-PSWSUSGroup -name $Config.DefaultPatchGroup
$AllApproved | Approve-PSWSUSUpdate -Action Install -Group $Groups -PassThru -whatif:$TestMode

#This is a list of all needed Patches including previously approved that are still not installed
$PendingPatches = Get-PSWSUSUpdate -IncludedInstallationState NotInstalled,Failed,Downloaded,InstalledPendingReboot
if($PendingPatches.count -ne 0) {   
    $UpdateSummary = Get-PSWSUSUpdateSummaryPerGroup -GroupName "All Computers" -UpdateObject $PendingPatches 
}else{
    $UpdateSummary=""
}

#Statistics
$NeededCount=0
#$UnknownCount=0
$RebootCount=0
$FailedCount=0
$DownloadedCount=0
$AllDeclined = $PreviewUpdates.Count + $SecOnlyUpdates.Count + $SuperSededUpdates.Count
$ApprovedTotal = $AllApproved.Count + $VSupdates.count

$UpdateSummary | ForEach-Object {
$NeededCount=$NeededCount+$_.Needed
$FailedCount=$FailedCount+$_.Failed
$DownloadedCount=$DownloadedCount+$_.Downloaded
$RebootCount=$RebootCount+$_.PendingReboot

}

#Main work is done - from here on out its all report generation

$SummaryTitleNew = "Newly Approved/Declined Patches"
$SummaryTitleActive = "New Patch Posture (All Servers)" 

"Last WSUS time with Microsoft: " + $LastSynch.endtime + " Result: " + $lastSynch.result
$SummaryTitleNew | Out-File $report -Append
$Spacer = "-------" 
$Spacer | Out-File $report -Append
$NewDeclined = "New Updates Declined: " + $AllDeclined
$NewDeclined | Out-File $report -Append
$NewApprovedAll = "New Updates Approved: " + $ApprovedTotal 
$NewApprovedAll | Out-File $report -Append
$NeededUpdatesPending = "Total Needed Updates: " + $PendingPatches.count.ToString() 
$NeededUpdatesPending | Out-File $report -Append
"`r`n" | Out-File $report -Append
$SummaryTitleActive |Out-File $report -Append
$Spacer | Out-File $report -Append
$TotalNeeded = "Total Needed Patches: " + $NeededCount 
$TotalNeeded | Out-File $report -Append
$TotalFailed = "Total Failed Patches: " + $FailedCount 
$TotalFailed | Out-File $report -Append
$TotalDownloaded = "Total Downloaded Patches: " + $DownloadedCount 
$TotalDownloaded | Out-File $report -Append
$TotalPendingReboots = "Total Patches Pending reboots: " + $RebootCount 
$TotalPendingReboots| Out-File $report -Append
"`r`n`n" | Out-File $report -Append


#Output declined updates to report
"Folowing new Preview updates have been declined per policy: " | Out-File $report -append #Updating the log file
"-----------------------" | Out-File $report -append #Updating the log file
$PreviewUpdates | Select Title,MsrcSeverity,CreationDate | Format-Table -Wrap -AutoSize | Out-String -width 4096 |Out-File $report -append
"Folowing new Security Only updates have been declined per policy: " | Out-File $report -append #Updating the log file
"-----------------------" | Out-File $report -append #Updating the log file
$SecOnlyUpdates | Select Title,MsrcSeverity,CreationDate | Format-Table -Wrap -AutoSize | Out-String -width 4096 |Out-File $report -append
"Folowing new Superseded updates have been declined per policy: " | Out-File $report -append #Updating the log file
"-----------------------" | Out-File $report -append #Updating the log file
$SuperSededUpdates | Select Title,MsrcSeverity,CreationDate | Format-Table -Wrap -AutoSize | Out-String -width 4096 |Out-File $report -append

#Output approved updates to report
"Folowing new updates have been approved per policy:" | Out-File $report -append #Updating the log file
"-----------------------" | Out-File $report -append #Updating the log file
$AllApproved | Select Title,MsrcSeverity,CreationDate | Format-Table -Wrap -AutoSize | Out-String -width 4096 |Out-File $report -append

#Output all pending patches
"Following Updates are pending for install on one or more machines: " | Out-File $report -Append
$UpdateSummary |Select @{Name="Update";expression={$_.UpdateTitle}},@{Name="Needed";expression={$_.NeededCount}},@{Name="Failed";expression={$_.FailedCount}},@{Name="Downloaded";expression={$_.DownloadedCount}},@{Name="Needs Reboot";expression={$_.InstalledPendingRebootCount}},@{Name="Unknown";expression={$_.UnknownCount}}| Format-Table -Wrap -AutoSize | Out-String -width 4096 |Out-File $report -append

#send email
$Attachment = $Report
$Subject = "Weekly Patch Approval Report for " + $Config.Environment + " Environment"
 


$BodyEmail = "<h1>Summary of Updates approved and declined for " + $config.Environment + " Windows Environment</h1><br>" + "<h3>" + $SummaryTitleNew + "</h3><br>" + $NewDeclined + "<br>" + $NewApprovedAll + "<br>" + $NeededUpdatesPending + "<br><br>" + "<h3>" + $SummaryTitleActive +"</h3><br>" + $TotalNeeded + "<br>" + $TotalFailed + "<br>" + $TotalPendingReboots + "<br>" + $TotalDownloaded + "<br><br>" +  "<h4>Please see attached report for additional details</h4>"

$message = New-Object System.Net.Mail.MailMessage $Config.FromEmail,$Config.ToEmail
$message.subject = $Subject
$Message.IsBodyHtml = $true
$message.Body = $BodyEmail
$message.Attachments.Add($Attachment)
$MailMessage = New-Object Net.Mail.SMTPClient($Config.SMTPServer)
$MailMessage.Send($message)

Disconnect-PSWSUSServer
