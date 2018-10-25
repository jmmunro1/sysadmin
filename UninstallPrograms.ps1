$program = Read-Host "Enter a program name"
write-host "Searcing for program..."
$app = Get-WmiObject -Query "Select * from win32_Product where name LIKE '$Program%'"
write-host "Uninstalling $app..."
$app.Uninstall()