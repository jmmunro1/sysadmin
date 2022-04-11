<#
    .Synopsis
        Removes user and any lingering objects.
    .Examples
#>

#Creates the Exchange sessions and necessary variables
$VerbosePreference = "Continue"
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://lbsmail.lbscares.com/PowerShell/ -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session -AllowClobber

$user = Read-Host -prompt "Enter userid"

$aduser = get-aduser $user

# Binding the users to DS
    $ou = [ADSI](“LDAP://” + $aduser)
    $sec = $ou.psbase.objectSecurity
 
    if ($sec.get_AreAccessRulesProtected())
    {
        $isProtected = $false ## allows inheritance
        $preserveInheritance = $true ## preserver inhreited rules
        $sec.SetAccessRuleProtection($isProtected, $preserveInheritance)
        $ou.psbase.commitchanges()
        Write-Host “$User is now inherting permissions”;
    }
    else
    {
        Write-Host “$User Inheritable Permission already set”
    }

#Removes the remote mailbox
Try
{
    remove-remotemailbox -identity $user -ErrorAction stop
    write-verbose -message "$user has been removed" 
}
catch
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName 
}
#Removes any remaining group associations
Try
{
    (Get-ADUser $user -Properties MemberOf).memberOf  | ForEach-Object { Remove-ADGroupMember -Identity $_ -Members $user -Verbose} -ErrorAction stop
    write-verbose -message "$user has been removed from all groups" 
}
Catch
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
}

#Removes user file share
try
{
    remove-item "\\lbscares.com\storage\group_documents\$user" -force -recurse -ErrorAction stop -Verbose
    write-verbose -message "$user file share has been removed"
}
Catch
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
}

#Information for confirmation e-mail
$params = @{
	Message = @{
		Subject = "User Removed"
		Body = @{
			ContentType = "Text"
			Content = "$user has been removed from all systems."
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