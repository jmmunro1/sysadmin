<#
    .Synopsis
        Collects password and account status information for a user and resets/unlocks the account
    .Examples
#>
        

#Required username parameter
Param (
     [Parameter(Mandatory=$true)][string]$Username)
      
#This block gathers account information and stores it in variables
$name = (get-aduser $username -property *).name  
$passwordlastset = (get-aduser $username -property *).passwordlastset
$passwordexpired = (get-aduser $username -property *).passwordexpired
$badlogoncount = (get-aduser $username -property *).badlogoncount
$lockedout = (get-aduser $username -property *).lockedout

#Displays the information to the user
write-host "User: $name"
write-host "Password last changed: $passwordlastset"
write-host "Password Expired: $passwordexpired"
write-host "Incorrect password count: $badlogoncount" 
write-host "Account locked out: $lockedout"

#Checks if the account account is locked, asks the user if they want to unlock, and then unlocks.
if ($lockedout -eq "True")
    
       {$unlock = read-host "Do you want to unlock account? Y/N"}
    
if ($unlock -eq "Y")
    
        {Unlock-ADAccount -Identity $username -verbose}
   
#Asks if the user wants to reset the password and stores answer in variable
#If they say yes then it resets the password the username variable plus 123
#It then sets the account to change password at next login   
$resetpassword = Read-Host -Prompt "Do you want to reset the password? Y/N"

if ($resetpassword -eq "Y")
    
        {set-adaccountpassword -verbose -Identity $username -Reset -NewPassword (convertto-securestring -asplaintext $username"123" -Force)`
          -Passthru | Set-ADUser -Identity $username -ChangePasswordAtLogon $True
         write-host "Password set to "$username"123"} 
    else
        {Read-Host -Prompt "Press Enter to Exit"}
    
        
    
