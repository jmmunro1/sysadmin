7<#
    .Synopsis
        Interactive script that creates a new remote mailbox, assigns ou, assigns distribution group, assigns licenses, sets up their copier code, and e-mails HR the login info.
    .Examples
#>

#Creates the Exchange sessions
$VerbosePreference = "Continue"
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://lbsmail.lbscares.com/PowerShell/ -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session -AllowClobber

#Collects User information
$name = Read-Host -prompt "Staff Name"
$email = Read-Host -prompt "E-mail Address"
$alias = Read-Host -prompt "User Alias"
$password = (convertto-securestring -asplaintext $alias"1234" -force )
get-organizationalunit | select canonicalname | ft
$ou = read-host -prompt "Organizational Unit"
get-distributiongroup  | select DisplayName | ft
$dg = read-host -prompt "Distribution Group"

#Creates mailbox and assigns distributiongroup
new-remotemailbox -name $name -userprincipalname $email -onpremisesorganizationalunit $ou -Password $password -ResetPasswordOnNextLogon $true
set-remotemailbox $name -EmailAddresses @{add="smtp:$email"}
set-remotemailbox $name -EmailAddressPolicyEnabled $false
set-remotemailbox $name -PrimarySmtpAddress $email
Add-DistributionGroupMember -Identity $dg -member $email
Write-Verbose -message "Mailbox has been created and assigned to distribution group"

<# 
    Connects to AD connect Server and forces sync.
#>
$session2 = New-PSSession -computername lbsmedia.lbscares.com -credential $UserCredential
Invoke-Command -Session $session2 -ScriptBlock {
	Import-Module -Name 'ADSync'
	Start-ADSyncSyncCycle -PolicyType Delta
}


Write-Verbose -message "Ad Sync started started"


<# 
    Connects to office 365 and assigns appropriate licenses.
#>
#Connects to office 365 and assigns appropriate licenses
Connect-MsolService -Credential $credential
$Timeout = 180
$timer = [Diagnostics.Stopwatch]::StartNew() 
#tests if the user exists every 30 seconds for 3 minutes
while (($timer.elapsed.totalseconds -lt $Timeout) -and (-not (get-msoluser -UserPrincipalName $email))) {
                start-sleep -seconds 30
                write-verbose -message "Waiting for user synchronization..."                
            }
            $timer.stop()

Set-MsolUser -userprincipalname $email -UsageLocation US
Set-MsolUserLicense -UserPrincipalName $email -addlicenses "lincolnbehavioral:STANDARDPACK"
Set-MsolUserLicense -UserPrincipalName $email -AddLicenses "lincolnbehavioral:ATP_ENTERPRISE"
Write-Verbose -message "Licenses have been assigned"



#Sends e-mail to necessary people using MS graph api

Connect-mgGraph -scopes "Mail.Send"
Import-module Microsoft.graph.users.actions

$params = @{
	Message = @{
		Subject = "New User"
		Body = @{
			ContentType = "Text"
			Content = "$Name was created with the e-mail address $email. The temporary password for the account is $alias'123'"
		}
		ToRecipients = @(
			@{
				EmailAddress = @{
					Address = "Krisc@lbscares.org"
				}
			}
		)
		CcRecipients = @(
			@{
				EmailAddress = @{
					Address = "bills@lbscares.org"
				}
			}
		)
	}
	SaveToSentItems = "false"
}

$Sender = Read-Host -prompt "Enter sender e-mail address"
Send-MgUserMail -UserId $sender -BodyParameter $params 
Write-Verbose -message "E-mail Sent"

#Connects to print server, forces user sync, waits 30 seconds, and sets copier pin
$session3 = New-PSSession -computername lbsprint.lbscares.com -credential $UserCredential
invoke-command -session $session3 -ScriptBlock { `
    $pin = Read-Host -prompt "Enter printer PIN Number" 
    $sync = (& cmd /c 'C:\Program Files\PaperCut MF\server\bin\win\server-command.exe' perform-user-and-group-sync > c:\temp1.txt)
    write-verbose -message "Waiting for user synchronization..."  
    start-sleep -seconds 30
    $setpin = (& cmd /c 'C:\Program Files\PaperCut MF\server\bin\win\server-command.exe' set-user-property $Using:alias secondary-card-number $pin > c:\temp3.txt)
    }

Remove-PSSession $Session
Remove-PSSession $Session2
Remove-PSSession $Session3
Read-Host -Prompt "Press Enter to exit"