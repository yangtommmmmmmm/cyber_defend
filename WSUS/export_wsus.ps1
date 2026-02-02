#WSUS export Auto

# Set the directory
$wsusToolsPath = Join-Path $env:programfiles "update services\tools"
$exportPath = "c:\WSUS\temp"

# Get the date for year-month
$yearMonth = Get-Date -Format "yyyy-MM"

# Get the date for rocyearmonth
$year = (Get-Date).Year
$month = (Get-Date).Month
$rocyear = $year - 1911
$rocyearmonth = "{0}{1:D2}" -f $rocyear,$month

#Setup the WSUS export directory
New-Item -Path "C:\Users\Administrator\Desktop\Scripts\$($rocyearmonth)" -ItemType Directory -Force

# Test whether the directory exists or not
if (-not (Test-Path $wsusToolsPath)) {
    Write-Error "$wsusToolsPath doesn't exist."
    exit 1
}

if (-not (Test-Path $exportPath)) {
    Write-Error "$exportPath doesn't exist."
    exit 1
}

# Execute exporting by wsusutil.exe
$wsusutil = Join-Path $wsusToolsPath "wsusutil.exe"
& $wsusutil export "c:\WSUS\temp\LC_$($yearMonth)_export.xml.gz" "c:\WSUS\temp\LC_$($yearMonth)_export.log"

#Copy the export.xml.gz and log to WSUS export directory
Copy-Item -Path "c:\WSUS\temp\*" -Destination "c:\Users\Administrator\Desktop\Scripts\$($rocyearmonth)" -Recurse -Force

#Copy the WSUSContent directories to WSUS export directory
$sourcePath = "C:\WSUS\WsusContent"
$destPath = "C:\Users\Administrator\Desktop\Scripts\$($rocyearmonth)"

if (-not (Test-Path $sourcePath)) {
    Write-Error "$sourcePath doesn't exist."
    exit 1
}

if (-not (Test-Path $destPath)) {
    Write-Error "$destPath doesn't exist."
    exit 1
}

$startOfMonth = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0
$endOfMonth = $startOfMonth.AddMonths(1)

Get-ChildItem -Path $sourcePath -Directory |
ForEach-Object {
    
    $dst = Join-Path $destPath $_.Name
    $folderCopied = $false

    if ($_.LastWriteTime.CompareTo($startOfMonth) -ge 0) {
        if ($_.LastWriteTime.CompareTo($endOfMonth) -lt 0) {
            New-Item $dst -ItemType Directory -Force | Out-Null
            Set-ItemProperty -Path $dst -Name LastWriteTime -Value $_.LastWriteTime
            $folderCopied = $true
        }
    }

    Get-ChildItem $_.FullName -File -Recurse | Where-Object { $_.LastWriteTime.CompareTo($startOfMonth) -ge 0 } |
    Where-Object { $_.LastWriteTime.CompareTo($endOfMonth) -lt 0 } | 
    ForEach-Object {
        if (-not $folderCopied) {
            New-Item $dst -ItemType Directory -Force | Out-Null
            $folderCopied = $true
        }

        $target = Join-Path $dst $_.FullName.Substring($_.DirectoryName.Length)
        New-Item (Split-Path $target) -ItemType Directory -Force | Out-Null

        Copy-Item $_.FullName $target -Force

    }
}
