# Define parameters for the script
param(
    # Source directory (Mandatory)
    [Parameter(Mandatory = $true)]
    [string]$s,
    
    # Target directory (Mandatory)
    [Parameter(Mandatory = $true)]
    [string]$t,
    
    # Specific file name (Optional)
    [Parameter(Mandatory = $false)]
    [string]$f,
    
    # File extension (Optional)
    [Parameter(Mandatory = $false)]
    [string]$e
)

# Function to test if a directory exists
function Test-DirectoryExists {
    param (
        [string]$dir,      # Directory path to test
        [string]$dirType   # Type of directory (Source or Target)
    )
    # If the directory does not exist, output an error and exit
    if (-not (Test-Path -Path $dir -PathType Container)) {
        Write-Error "$dirType directory does not exist: $dir"
        exit 1
    }
}

# Function to initialize the file filter based on file name and extension
function Initialize-Filter {
    param (
        [string]$fileName,   # Specific file name
        [string]$extension   # File extension
    )
    $filter = "*"
    if ($fileName) {
        # Use the specific file name
        $filter = $fileName
        if ($extension) {
            # Append the extension to the file name
            $filter += ".$extension"
        }
    }
    elseif ($extension) {
        # Use all files with the specified extension
        $filter = "*.$extension"
    }
    return $filter
}

# Function to get the count of files in a directory matching the filter
function Get-FileCount {
    param (
        [string]$dir,     # Directory path
        [string]$filter   # File filter
    )
    # Return the number of files found
    return (Get-ChildItem -Path $dir -Filter $filter -Recurse -ErrorAction SilentlyContinue).Count
}

# Function to copy files from source to target directory
function Copy-Files {
    param (
        [string]$sourceDir,  # Source directory path
        [string]$targetDir,  # Target directory path
        [string]$filter      # File filter
    )
    Write-Host "Copying initial files from source to target directory..."
    # Get all files matching the filter in the source directory recursively
    Get-ChildItem -Path $sourceDir -Filter $filter -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        # Determine the corresponding path in the target directory
        $targetPath = $_.FullName -replace [regex]::Escape($sourceDir), [regex]::Escape($targetDir)
        $targetDirPath = Split-Path -Path $targetPath
        # If the target directory path does not exist, create it
        if (-not (Test-Path -Path $targetDirPath)) {
            New-Item -ItemType Directory -Path $targetDirPath | Out-Null
            Write-Host "Created target directory: $targetDirPath"
        }
        # If the file paths are not identical, copy the file
        if ($_.FullName -ne $targetPath) {
            try {
                Copy-Item -Path $_.FullName -Destination $targetPath -Force
            }
            catch {
                # Output an error message if the copy fails
                Write-Error "Failed to copy '$( $_.Name )': $_"
            }
        }
    }
}

# Function to update files in the target directory when a change is detected
function global:Update-Files {
    param (
        [string]$path,        # Path of the changed file
        [string]$changeType   # Type of change detected
    )
    
    # Define the corresponding target path by replacing the source directory path with the target directory path
    $targetPath = $path -replace [regex]::Escape($s), [regex]::Escape($t)
    $targetDir = Split-Path -Path $targetPath

    # Ensure the target directory exists
    if (-not (Test-Path -Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    # Copy the updated file to the target path
    Copy-Item -Path $path -Destination $targetPath -Force
}

# Function to initialize the file system watcher
Function Initialize-FileWatcher {
    param (
        [string]$sourceDir,  # Source directory to monitor
        [string]$filter      # File filter
    )

    # Check if the source directory exists before proceeding
    if (-not (Test-Path -Path $sourceDir -PathType Container)) {
        Write-Error "Source directory does not exist: $sourceDir"
        return
    }

    # Initialize FileSystemWatcher for the source directory
    $watcher = New-Object IO.FileSystemWatcher $sourceDir

    # Include subdirectories in the watcher
    $watcher.IncludeSubdirectories = $true
    # Enable raising events
    $watcher.EnableRaisingEvents = $true
    # Set the filter for the watcher
    $watcher.Filter = $filter

    # Define the action to take when a change is detected
    $changeAction = {
        $path = $Event.SourceEventArgs.FullPath      # Full path of the changed file
        $changeType = $Event.SourceEventArgs.ChangeType  # Type of change
        $timeStamp = $Event.TimeGenerated            # Time of the event
        try {
            # Update the file in the target directory
            Update-Files -path $path -changeType $changeType
        }
        catch {
            # Output an error message if handling the change fails
            Write-Error "Failed to handle file change: $_"
        }
    }
    
    # Register the event handler for changes (Modified files)
    Register-ObjectEvent $watcher Changed -Action $changeAction
}

# Test if the source and target directories exist
Test-DirectoryExists -dir $s -dirType "Source"
Test-DirectoryExists -dir $t -dirType "Target"

# Check if source and target directories are the same
if ($s -eq $t) {
    Write-Error "Source and target directories cannot be the same."
    exit 1
}

# Initialize the file filter based on input parameters
$filter = Initialize-Filter -fileName $f -extension $e

# Get the count of files in source and target directories
$sourceFileCount = Get-FileCount -dir $s -filter $filter
$targetFileCount = Get-FileCount -dir $t -filter $filter
Write-Host "Amount of selected files in directories: src = $sourceFileCount, target = $targetFileCount."

# Copy the initial set of files from source to target
Copy-Files -sourceDir $s -targetDir $t -filter $filter

# Initialize the file watcher to monitor changes in the source directory
Initialize-FileWatcher -sourceDir $s -filter $filter

while ($true) {
    Wait-Event -Timeout 1
}
