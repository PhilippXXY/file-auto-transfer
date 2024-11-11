# File Auto Transfer

## Overview

The **File Auto Transfer** script is a PowerShell utility designed to monitor a source directory for any file changes and automatically copy updated files to a target directory. This eliminates the manual overhead of copying and pasting files, streamlining the development process, and reducing the time spent on routine tasks.

## Features

- **Continuous Monitoring**: Watches for changes in real-time and updates the target directory instantly.
- **Recursive Copying**: Supports copying of files within subdirectories, maintaining the source directory structure.
- **Flexible Filtering**: Allows specification of filenames and extensions to monitor specific files or types.
- **Easy Integration**: Ideal for local development environments without CI/CD pipelines.

## Use Cases

- **Development Automation**: Automatically deploy binaries or assets to a test environment after each build.
- **File Synchronization**: Keep local and remote directories in sync during development.
- **Backup Automation**: Continuously back up important files whenever changes occur.

### Example Scenario

You're developing a Java component and need the generated binary file to be available in a specific program or environment. By using this script, every time the binary is updated, it is automatically copied to the target location, ensuring that you're always working with the latest version without manual intervention.

## Prerequisites

- **PowerShell**: Make sure PowerShell is installed on your system (version 5.0 or later recommended).
- **Permissions**: Ensure you have read access to the source directory and write access to the target directory.
- **Execution Policy**: You may need to set the execution policy to allow running scripts:
    ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  ```
  or
  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
  ```

## Installation

1. **Clone the Repository**: Download or clone the script to your local machine.
2. **Navigate to the Script Directory**:
   ```powershell
   cd "path\to\file-auto-transfer\src"
   ```

## Usage

Run the script using PowerShell with the required parameters:
```powershell
.\fat.ps1 -s path\to\source\directory -t path\to\target\directory [-f filename] [-e extension]
```

### Parameters

- **Mandatory**
  - ```-s```: Path to the source directory to be monitored.
  - ```-t```: Path to the target directory where files will be copied.
- **Optional**
  - ```-f```: Specific file name to monitor within the source directory.
  - ```-e```: Specific file extension to monitor within the source directory.

### Parameter Details

- **Monitor All Files:**
  ```powershell
    .\fat.ps1 -s C:\Projects\Source -t C:\Projects\Target
  ```
- **Monitor Specific Extension:**
  ```powershell
    .\fat.ps1 -s C:\Projects\Source -t C:\Projects\Target -e .extension
  ```
- **Monitor Specific File:**
  ```powershell
   .\fat.ps1 -s C:\Projects\Source -t C:\Projects\Target -f file.name
  ```

## Notes

- **Continuous Operation:** The script will keep running and monitoring changes until you manually stop it by closing the PowerShell window or pressing ```Ctrl+C```.
- **Directory Structure Preservation:** The script preserves the directory structure of the source within the target directory.
- **Source and Target Must Differ:** Make sure the source and target directories are not the same to prevent recursive copying and potential errors.

## Troubleshooting

- **Script Not Running:** Ensure that your execution policy allows running scripts and that you're running PowerShell with adequate permissions.
- **No Files Are Copied:** Verify that the source directory contains files matching your filter criteria (```-f``` or ```-e```) and that changes are being made.
- **Access Denied Errors:** Check that you have the necessary read/write permissions for both the source and target directories.
