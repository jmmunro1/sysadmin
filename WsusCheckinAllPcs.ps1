$cred = get-credential
$pcs = (get-adcomputer -filter *).name | sort

Foreach ($computer in $computers) {
    $connection = test-connection $computer -count 1 -quiet

    if ($connection -eq "true") 
    {
        try
            {
            Force-WSUSCheckin -computer $computer
            }
        Catch
            {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName 
            }
    }
    else
    {
        write-host $computer 'is unavailable'
    }
}