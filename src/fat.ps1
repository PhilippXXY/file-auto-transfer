param(
    [Parameter(Mandatory = $true)]
    [string]$s, # Source directory
    
    [Parameter(Mandatory = $true)]
    [string]$t, # Target directory
    
    [Parameter(Mandatory = $false)]
    [string]$f, # Specific file name
    
    [Parameter(Mandatory = $false)]
    [string]$e   # File extension
)

function Test-DirectoryExists {
    param (
        [string]$dir,
        [string]$dirType
    )
    if (-not (Test-Path -Path $dir -PathType Container)) {
        Write-Error "$dirType directory does not exist: $dir"
        exit 1
    }
}

function Initialize-Filter {
    param (
        [string]$fileName,
        [string]$extension
    )
    $filter = "*"
    if ($fileName) {
        $filter = $fileName
        if ($extension) {
            $filter += ".$extension"
        }
    }
    elseif ($extension) {
        $filter = "*.$extension"
    }
    return $filter
}

function Get-FileCount {
    param (
        [string]$dir,
        [string]$filter
    )
    return (Get-ChildItem -Path $dir -Filter $filter -Recurse -ErrorAction SilentlyContinue).Count
}


function Copy-Files {
    param (
        [string]$sourceDir,
        [string]$targetDir,
        [string]$filter
    )
    Write-Host "Copying initial files from source to target directory..."
    Get-ChildItem -Path $sourceDir -Filter $filter -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $targetPath = $_.FullName -replace [regex]::Escape($sourceDir), [regex]::Escape($targetDir)
        $targetDirPath = Split-Path -Path $targetPath
        if (-not (Test-Path -Path $targetDirPath)) {
            New-Item -ItemType Directory -Path $targetDirPath | Out-Null
            Write-Host "Created target directory: $targetDirPath"
        }
        if ($_.FullName -ne $targetPath) {
            try {
                Copy-Item -Path $_.FullName -Destination $targetPath -Force
            }
            catch {
                Write-Error "Failed to copy '$( $_.Name )': $_"
            }
        }
    }
}

function global:Update-Files {
    param (
        [string]$path,
        [string]$changeType
    )
    
    # Define the target path
    $targetPath = $path -replace [regex]::Escape($s), [regex]::Escape($t)
    $targetDir = Split-Path -Path $targetPath

    # Ensure target directory exists
    if (-not (Test-Path -Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    # Copy the file
    Copy-Item -Path $path -Destination $targetPath -Force
}

Function Initialize-FileWatcher {
    param (
        [string]$sourceDir,
        [string]$filter
    )

    # Check if the source directory exists before proceeding
    if (-not (Test-Path -Path $sourceDir -PathType Container)) {
        Write-Error "Source directory does not exist: $sourceDir"
        return
    }

    # Initialize FileSystemWatcher with only the source directory
    $watcher = New-Object IO.FileSystemWatcher $sourceDir

    # Set properties
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true
    $watcher.Filter = $filter

    $changeAction = {
        $path = $Event.SourceEventArgs.FullPath
        $changeType = $Event.SourceEventArgs.ChangeType
        $timeStamp = $Event.TimeGenerated
        try {
            Update-Files -path $path -changeType $changeType
        }
        catch {
            Write-Error "Failed to handle file change: $_"
        }
    }
    
    # Register the event
    Register-ObjectEvent $watcher Changed -Action $changeAction
}

Test-DirectoryExists -dir $s -dirType "Source"
Test-DirectoryExists -dir $t -dirType "Target"

if ($s -eq $t) {
    Write-Error "Source and target directories cannot be the same."
    exit 1
}

$filter = Initialize-Filter -fileName $f -extension $e

$sourceFileCount = Get-FileCount -dir $s -filter $filter
$targetFileCount = Get-FileCount -dir $t -filter $filter
Write-Host "Amount of selected files in directories: src = $sourceFileCount, target = $targetFileCount."

Copy-Files -sourceDir $s -targetDir $t -filter $filter

Initialize-FileWatcher -sourceDir $s -filter $filter

# Keep the script running to monitor file changes
Write-Host "FileWatcher is monitoring changes. Press Ctrl+C to stop the script."
while ($true) {
    Wait-Event -Timeout 1
}
