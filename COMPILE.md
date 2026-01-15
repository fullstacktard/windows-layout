# Compilation Guide

This guide explains how to compile Window Layout Manager into a standalone executable.

## Prerequisites

1. **Install AutoHotkey v2**
   - Download from: https://www.autohotkey.com/download/
   - Choose the "Current version" (v2.0+)
   - Run the installer and follow the prompts

2. **Install Ahk2Exe Compiler** (included with AutoHotkey v2)
   - The compiler is automatically installed with AutoHotkey v2
   - Located at: `C:\Program Files\AutoHotkey\Compiler\`

## Method 1: Right-Click Compile (Easiest)

1. Navigate to the project directory
2. Right-click on `WindowLayoutManager.ahk`
3. Select **"Compile Script"** from the context menu
4. Wait for compilation to complete
5. Find `WindowLayoutManager.exe` in the same directory

### Compilation Options:
- **Base File**: Uses the default AutoHotkey v2 base file
- **Icon**: You can add a custom icon later (see Advanced section)

## Method 2: Using Ahk2Exe GUI

1. Open the Ahk2Exe compiler:
   - Start Menu → AutoHotkey → Convert .ahk to .exe
   - Or navigate to: `C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe`

2. Configure compilation:
   - **Source (script file)**: Browse to `WindowLayoutManager.ahk`
   - **Destination (.exe file)**: Choose output location and name
   - **Base File**: Select AutoHotkey64.exe (for 64-bit)
   - **Icon**: (Optional) Select a custom .ico file
   - **Compression**: Use UPX compression for smaller file size

3. Click **Convert** to compile

4. Wait for "Compilation complete" message

## Method 3: Command Line

Open Command Prompt or PowerShell in the project directory:

```batch
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "WindowLayoutManager.ahk" /out "WindowLayoutManager.exe"
```

### With Custom Icon:
```batch
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "WindowLayoutManager.ahk" /out "WindowLayoutManager.exe" /icon "icon.ico"
```

### With Compression:
```batch
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "WindowLayoutManager.ahk" /out "WindowLayoutManager.exe" /compress 1
```

## Advanced Options

### Custom Icon

1. Create or download a 256x256 .ico file
2. Place it in the project directory (e.g., `icon.ico`)
3. Add to the script (at the top of WindowLayoutManager.ahk):
   ```autohotkey
   TraySetIcon("icon.ico")
   ```
4. Compile with icon parameter

### UPX Compression

UPX reduces executable size:

1. Download UPX: https://upx.github.io/
2. Extract `upx.exe` to: `C:\Program Files\AutoHotkey\Compiler\`
3. Use `/compress 1` or `/compress 2` when compiling

### Version Information

Add version info to the executable by creating a file named `WindowLayoutManager.ahk.properties`:

```ini
[Details]
Name=Window Layout Manager
Description=Save and restore window layouts
Version=1.0.0
Company=Your Name
Copyright=Copyright © 2025
OrigFilename=WindowLayoutManager.exe
ProductName=Window Layout Manager
ProductVersion=1.0.0
```

Place this file in the same directory as the .ahk file before compiling.

### Resource Include (MPRESS)

For even better compression, use MPRESS:

1. Download MPRESS: http://www.matcode.com/mpress.htm
2. Extract `mpress.exe` to: `C:\Program Files\AutoHotkey\Compiler\`
3. Compile normally, then run:
   ```batch
   mpress.exe WindowLayoutManager.exe
   ```

## Build Script

Create a `build.bat` file for automated compilation:

```batch
@echo off
echo Building Window Layout Manager...

set AHK_COMPILER="C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
set SOURCE=WindowLayoutManager.ahk
set OUTPUT=WindowLayoutManager.exe
set ICON=icon.ico

REM Check if compiler exists
if not exist %AHK_COMPILER% (
    echo Error: AutoHotkey compiler not found!
    echo Please install AutoHotkey v2 from https://www.autohotkey.com/
    pause
    exit /b 1
)

REM Compile the script
if exist %ICON% (
    %AHK_COMPILER% /in %SOURCE% /out %OUTPUT% /icon %ICON% /compress 1
) else (
    %AHK_COMPILER% /in %SOURCE% /out %OUTPUT% /compress 1
)

if errorlevel 1 (
    echo Error: Compilation failed!
    pause
    exit /b 1
)

echo.
echo Compilation successful!
echo Output: %OUTPUT%
echo.

REM Show file size
for %%A in (%OUTPUT%) do echo File size: %%~zA bytes

pause
```

Run with: `build.bat`

## Troubleshooting

### "Unable to open the script file"
- Verify the path to the .ahk file is correct
- Check file permissions
- Ensure the file exists and is not open in another program

### "Unable to load base file"
- Reinstall AutoHotkey v2
- Verify AutoHotkey installation directory
- Check that AutoHotkey64.exe exists in the compiler folder

### "Icon file not found"
- Verify icon file path is correct
- Use absolute path if relative path fails
- Ensure icon is in .ico format (not .png or .jpg)

### Compilation is slow
- Disable antivirus temporarily
- Use /compress 0 to skip compression
- Close other programs to free up system resources

### Compiled .exe doesn't run
- Check Windows Defender / antivirus (may flag as false positive)
- Run as administrator if needed
- Verify all library files are included via #Include

### Missing functionality in compiled version
- Ensure all #Include paths are correct
- Use relative paths for includes (lib\*.ahk)
- Test the script before compiling

## Testing the Compiled Executable

1. Copy the compiled .exe to a test location
2. Run the .exe (not the .ahk script)
3. Test all features:
   - Create a profile
   - Capture layout
   - Restore layout
   - Assign hotkey
   - System tray menu
   - Auto-start

4. Check for errors or missing functionality

## Distribution

After successful compilation:

1. **Single File Distribution**:
   - Distribute `WindowLayoutManager.exe` alone
   - No dependencies required

2. **With Documentation**:
   - Include README.md
   - Include example profiles (optional)

3. **Installer** (Advanced):
   - Use Inno Setup or NSIS to create an installer
   - Include Start Menu shortcuts
   - Auto-create startup folder shortcut

### Creating an Installer with Inno Setup

1. Download Inno Setup: https://jrsoftware.org/isinfo.php
2. Create a script file `installer.iss`:

```ini
[Setup]
AppName=Window Layout Manager
AppVersion=1.0.0
DefaultDirName={autopf}\WindowLayoutManager
DefaultGroupName=Window Layout Manager
OutputBaseFilename=WindowLayoutManager-Setup
Compression=lzma2
SolidCompression=yes

[Files]
Source: "WindowLayoutManager.exe"; DestDir: "{app}"
Source: "README.md"; DestDir: "{app}"

[Icons]
Name: "{group}\Window Layout Manager"; Filename: "{app}\WindowLayoutManager.exe"
Name: "{group}\Uninstall"; Filename: "{uninstallexe}"
Name: "{autostartup}\Window Layout Manager"; Filename: "{app}\WindowLayoutManager.exe"; Parameters: "/minimize"

[Run]
Filename: "{app}\WindowLayoutManager.exe"; Description: "Launch Window Layout Manager"; Flags: postinstall nowait skipifsilent
```

3. Compile the installer with Inno Setup

## File Size Optimization

Typical file sizes:
- Uncompressed: ~2-3 MB
- With UPX compression: ~800 KB - 1.2 MB
- With MPRESS: ~700 KB - 1 MB

To minimize size:
1. Use UPX compression (level 2)
2. Remove debug code
3. Optimize includes (only include what's needed)
4. Use MPRESS for final compression

## Security Notes

**Code Signing** (Optional but Recommended):
- Unsigned executables may trigger SmartScreen warnings
- Consider code signing certificate for professional distribution
- Cost: ~$50-200/year from certificate authorities

**Antivirus False Positives**:
- Compiled AHK scripts sometimes trigger antivirus
- Submit to vendors for whitelisting if needed
- Consider using VirusTotal to check

## Support

For compilation issues:
1. Check AutoHotkey forums: https://www.autohotkey.com/boards/
2. Verify AutoHotkey v2 installation
3. Review error messages carefully

---

**Happy Compiling!**
