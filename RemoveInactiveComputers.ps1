# Powershell function to remove inactive active directory computer accounts.
# Author: Josh Munro

Function Remove-InactiveComputers {
    <#
    .Synopsis
        Removes inactive computer accounts from AD based on the last logon date.
    .Example
        Remove-InactiveComputers -DaysInactive 60
        Removes all computers accounts that have not been logged into in the last 60 days.
    #>

    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Int]$DaysInactive
    )
    $cred = get-credential
    $date = (get-date).adddays(-$DaysInactive)
    $InactivePC = get-adcomputer -filter * -Properties lastlogondate | Where-Object lastlogondate -lt $date
    $InactivePC | ForEach-Object {
    Try {
        remove-adobject $_ -Verbose -recursive -Credential $cred -Confirm:$false
        write-verbose "Removed computer account $($_)"
        } 
    Catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName 
        }
    }
}