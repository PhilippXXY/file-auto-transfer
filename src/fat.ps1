param(
    [Parameter(Mandatory=$true)]
    [string]$s,  # Source directory
    
    [Parameter(Mandatory=$true)]
    [string]$t,  # Target directory
    
    [Parameter(Mandatory=$false)]
    [string]$f,  # Specific file name
    
    [Parameter(Mandatory=$false)]
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
    } elseif ($extension) {
        $filter = "*.$extension"
    }
    return $filter
}

function Initialize-FileWatcher {
    param (
        [string]$sourceDir,
        [string]$filter
    )
    $watcher = New-Object System.IO.FileSystemWatcher   
    $watcher.Path = $sourceDir
    $watcher.Filter = $filter   
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true    
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName, [System.IO.NotifyFilters]::LastWrite
    return $watcher
}

function Register-FileWatcherEvents {
    param (
        [System.IO.FileSystemWatcher]$watcher
    )
    $debounceInterval = 1 # seconds
    $eventTimes = @{}

    $action = {
        $path = $Event.SourceEventArgs.FullPath
        $name = $Event.SourceEventArgs.Name
        $changeType = $Event.SourceEventArgs.ChangeType
        $timeStamp = $Event.TimeGenerated

        if ($eventTimes.ContainsKey($path)) {
            $lastEventTime = $eventTimes[$path]
            if (($timeStamp - $lastEventTime).TotalSeconds -lt $debounceInterval) {
                return
            }
        }
        $eventTimes[$path] = $timeStamp
        Write-Host "The file '$name' was $changeType at $timeStamp"
    }
    Register-ObjectEvent $watcher "Created" -Action $action
    Register-ObjectEvent $watcher "Changed" -Action $action
}

function Get-FileCount {
    param (
        [string]$dir,
        [string]$filter
    )
    return (Get-ChildItem -Path $dir -Filter $filter -Recurse).Count
}

function Copy-Files {
    param (
        [string]$sourceDir,
        [string]$targetDir,
        [string]$filter
    )
    Get-ChildItem -Path $sourceDir -Filter $filter -Recurse | ForEach-Object {
        $targetPath = $_.FullName -replace [regex]::Escape($sourceDir), [regex]::Escape($targetDir)
        if ($_.FullName -ne $targetPath) {
            Copy-Item -Path $_.FullName -Destination $targetPath -Force
        }
    }
}

# Main script execution
Test-DirectoryExists -dir $s -dirType "Source"
Test-DirectoryExists -dir $t -dirType "Target"

if ($s -eq $t) {
    Write-Error "Source and target directories cannot be the same."
    exit 1
}

$filter = Initialize-Filter -fileName $f -extension $e

$sourceFileCount = Get-FileCount -dir $s -filter $filter
$targetFileCount = Get-FileCount -dir $t -filter $filter
Write-Host "Amount of selected files in directories: src[$sourceFileCount] target[$targetFileCount]."
Write-Host "Target directory contains $targetFileCount files."

Copy-Files -sourceDir $s -targetDir $t -filter $filter

$watcher = Initialize-FileWatcher -sourceDir $s -filter $filter
Register-FileWatcherEvents -watcher $watcher

