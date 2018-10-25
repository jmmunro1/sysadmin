﻿$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://lincolnmail.lbscares.com/PowerShell/ -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session
Get-Queue | Select Identity, Status, MessageCount | export-csv "\\filedomain\data\IT Dept\queue\queue$(get-date -f yyyyMMdd).csv"
Read-Host -Prompt "Press Enter to exit"