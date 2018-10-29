function Get-FolderHash ($folder) {
 dir $folder -Recurse | ?{!$_.psiscontainer} | %{[Byte[]]$contents += [System.IO.File]::ReadAllBytes($_.fullname)}
 $hasher = [System.Security.Cryptography.SHA1]::Create()
 [string]::Join("",$($hasher.ComputeHash($contents) | %{"{0:x2}" -f $_}))
}

Remove-Item "\\FolderToClear" -Recurse

#Create Array To Store File Locations and hashes
$OriginalFilesLocation = @()
$OriginalFileHash = @()
$NewFilesHashArray = @()
$OriginalFilesHashArray = @()
$NewFileHash = @()
$NewFiles = @()


#Folder Locations
$OrgininalFolderLocations = @()
$OriginalFolderHash = @()
$NewFolderArray = @()
$OriginalFoldersHashArray = @()
$NewFoldersHash = @()
$NewFolders = @()
$NewFolderHashArray = @()


#Use text document to set files or locations to be copied
$OriginalFilesLocation = Get-Content "OriginalFiles.txt"
$OriginalFiles = Get-Item $OriginalFilesLocation




#Hash Original Files
Foreach ($OriginalFile in $OriginalFiles) 
{
    $OriginalFileHash = Get-FileHash $OriginalFile | Select Path,Hash
    $OriginalFilesHashArray += $OriginalFileHash
}


#Use array to copy files
Foreach ($OriginalFileHashArray in $OriginalFilesHashArray)
{
$CopiedFile = Copy-Item -Path $OriginalFileHashArray.Path -Destination '\\EndLocation\' -Force -PassThru -Container -Recurse
Write-Host "I've Just Copied $($CopiedFile)"
}


#Hash New File Location
$NewFiles = Get-Item "\\EndLocation\*"
Foreach ($NewFile in $NewFiles) 
{
    $NewFileHash = Get-FileHash $NewFile | Select Path,Hash | Sort Hash
    $NewFilesHashArray += $NewFileHash
}


#Compare New and Old Location
$diff = Compare-Object -ReferenceObject $OriginalFilesHashArray.hash -DifferenceObject $NewFilesHashArray.hash
if($diff)
{
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("Files Don't Match, Please Troubleshoot",0,"Done",0x1)
}
else
{
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("File Copy Succesful",0,"Done",0x1)
}



#Use text document to set files or locations to be copied
$OriginalFolderLocations = Get-Content "OriginalFolders.txt"


#Hash Original Folders
Foreach ($OriginalFolderLocation in $OriginalFolderLocations) 
{
    $OriginalFolderHash = Get-FolderHash $OriginalFolderLocation | Out-String
    $OriginalFoldersHashArray += $OriginalFolderHash
}

#Use array to copy files
Foreach ($OriginalFolderLocation in $OriginalFolderLocations)
{
$CopiedFolder = Copy-Item -Path $OriginalFolderLocation -Destination '\\EndLocation\' -Force -PassThru -Container -Recurse
Write-Host "I've Just Copied $($CopiedFolder)"
}

#Hash New File Location
$NewFolders = Get-ChildItem "\\EndLocation\*" -Directory
Foreach ($NewFolder in $NewFolders) 
{
    $NewFolderHash = Get-FolderHash $NewFolder
    $NewFolderHashArray += $NewFolderHash | Out-String
}

#Compare New and Old Location
$diff = Compare-Object -ReferenceObject $OriginalFoldersHashArray -DifferenceObject $NewFolderHashArray
if($diff)
{
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("Folders Don't Match, Please Troubleshoot",0,"Done",0x1)
}
else
{
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("Folder Copy Succesful",0,"Done",0x1)
}

New-Item -ItemType directory -Path "\\EndLocation\Folder" -Force
Move-Item -Path "\\EndLocation\* SF Renewals.xlsx" -Destination "\\EndLocation\Folder" -Force