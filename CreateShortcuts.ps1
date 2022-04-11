$deskTopPath = [Environment]::GetfolderPath("Desktop")
$allDesktopPath = [Environment]::Getfolderpath("CommonDesktopdirectory")
$currentShortcuts = ,@(get-childitem -path $deskTopPath, $allDesktopPath | select basename )

$shortcutlist = @{
    "\\ADP.url" = "http://workforcenow.adp.com"
    "\\eCris.url" = "http://pcesecure.com/dcs"
    "\\Office.url" = "http://office.com"
    "\\LBSLink.url" = "http://lincolnbehavioral.sharepoint.com"
    "\\Excel 2016.lnk" = "C:\Program Files (x86)\Microsoft Office\Office16\EXCEL.EXE"
    "\\Outlook 2016.lnk" = "C:\Program Files (x86)\Microsoft Office\Office16\OUTLOOK.EXE"
}

foreach ( $shortcut in $shortcutlist.GetEnumerator()) {

    $splitShortCut = ($shortcut.name).split("\.")[2]

    If ($currentShortcuts.basename -contains $splitShortCut) {

        write-host "Shortcut for $($splitShortCut) already exists."

    }

    else

    {

        $new_object = New-Object -ComObject WScript.Shell
        $destination = $new_object.SpecialFolders.Item("AllUsersDesktop")
        $source_path = Join-Path -Path $destination -ChildPath $shortcut.name
        $source = $new_object.CreateShortcut($source_path)
        $source.TargetPath = $shortcut.value
        $source.Save()
        write-host "Created shortcut for $($splitShortCut)"
    }
}

$checkPrinter = get-printer | where {$_.shareName -eq 'FollowMe_Plaza'}
If (-not $checkPrinter) { 
    add-printer -ShareName 'FollowMe_Plaza'
    }
else
    {
    write-host 'Printer is already installed'
    } 


    
    
