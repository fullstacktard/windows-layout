# Window Layout Manager v1.0.1

A powerful Windows 11 desktop application that saves and restores window layouts across multiple virtual desktops with custom hotkey support.

[![npm version](https://img.shields.io/npm/v/windows-layout.svg)](https://www.npmjs.com/package/windows-layout)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Windows 11](https://img.shields.io/badge/Platform-Windows%2011-blue.svg)](https://www.microsoft.com/windows/windows-11)

## Installation

### Via npm (Recommended)

```bash
npm install windows-layout
```

After installation, run from the command line:

```bash
windows-layout
```

### Manual Installation

1. Download the latest release from [GitHub Releases](https://github.com/fullstacktard/windows-layout/releases)
2. Extract to your preferred location
3. Run `WindowLayoutManager.exe`

### From Source

1. Install [AutoHotkey v2](https://www.autohotkey.com/download/)
2. Clone this repository: `git clone https://github.com/fullstacktard/windows-layout.git`
3. Run `WindowLayoutManager.ahk`

## CLI Usage

```bash
# Start the application
windows-layout

# Start minimized to system tray
windows-layout start --minimized

# Restore a specific profile
windows-layout restore "Work Setup"

# Show help
windows-layout help

# Show installation info
windows-layout info
```

## Programmatic Usage

```javascript
const windowLayout = require('windows-layout');

// Start the application
await windowLayout.start();

// Start minimized
await windowLayout.start({ minimized: true });

// Restore a specific profile
await windowLayout.restore('Work Setup');

// Get installation paths
const paths = windowLayout.getPaths();
console.log(paths.profiles); // Profile storage directory
```

## Features

- **Profile Management**: Create, edit, delete, and duplicate window layout profiles
- **Virtual Desktop Support**: Seamlessly works across multiple Windows 11 virtual desktops
- **Smart Window Capture**: Automatically captures window positions, sizes, and desktop assignments across all desktops
- **Intelligent Restore**: Launches missing applications and repositions existing windows without duplicating instances
  - **UWP/Store App Support**: Automatically launches Windows Store apps (WhatsApp, Calculator, etc.) using shell:AppsFolder
  - **Robust Error Handling**: Continues restoring even if individual windows fail
  - **Per-Desktop Cleanup**: Only minimizes windows on the same desktop they shouldn't be on
- **Custom Hotkeys**: Assign keyboard shortcuts to quickly restore any profile
  - **Hotkey Recorder**: Visual hotkey recorder in profile editor - just press your desired keys
- **Default Profile & Auto-Restore**: Set a default profile that automatically restores on Windows startup
- **System Tray Integration**: Quick access to all features from the system tray
- **Progress Indicator**: Clean taskbar-based progress window instead of blocking overlay
- **Auto-Start**: Optional Windows startup integration
- **Multiple Instance Handling**: Distinguishes between multiple windows of the same application (e.g., multiple Chrome windows)
- **Export JSON**: Copy profile data to clipboard for sharing or backup
- **Desktop Return**: Automatically returns to your original desktop after restoration
- **Error Handling**: Gracefully handles corrupted profiles with visual warnings
- **Detailed Logging**: All restore operations are logged to %AppData%\WindowLayoutManager\Logs\

## Requirements

- Windows 11 (build 22000 or later)
- AutoHotkey v2.0 or later (for running from source)

## Installation

### Option 1: Run from Source

1. Download and install [AutoHotkey v2](https://www.autohotkey.com/download/)
2. Clone or download this repository
3. Double-click `WindowLayoutManager.ahk` to run

### Option 2: Compile to EXE

1. Install AutoHotkey v2
2. Right-click `WindowLayoutManager.ahk`
3. Select "Compile Script" from the context menu
4. Run the generated `WindowLayoutManager.exe`

## Quick Start Guide

### 1. First Launch

When you first launch Window Layout Manager:
- The application will minimize to your system tray
- Right-click the tray icon to access the menu
- Select "Open Settings" to view the main window

### 2. Creating Your First Profile

**Method 1: From Main Window**
1. Arrange your windows exactly how you want them across virtual desktops
2. Open Window Layout Manager
3. Click "New Profile"
4. Enter a name (e.g., "Work Setup")
5. Click OK - the app will automatically switch through your virtual desktops to capture all windows (~6 seconds)

**Method 2: From Tray Menu**
1. Arrange your windows across all desktops
2. Right-click the tray icon
3. Select "Capture Current Layout"
4. Enter a profile name

**Note**: During capture, the app will briefly switch between virtual desktops to enumerate all windows. This is a Windows API limitation.

### 3. Setting Up Hotkeys

**Method 1: Hotkey Recorder** (Recommended)
1. Open a profile in the editor
2. Click "Record Keys" button
3. Press your desired key combination (e.g., Ctrl+Alt+1)
4. The hotkey will be automatically recorded
5. Click "Save Changes"

**Method 2: Manual Entry**
1. Edit a profile
2. Type the hotkey in AutoHotkey format (e.g., `^!1` for Ctrl+Alt+1)
3. Click "Save Changes"

### 4. Restoring a Layout

**Method 1: Using Hotkeys** (Fastest)
1. Press your assigned hotkey anytime
2. Windows will restore to their saved positions
3. You'll automatically return to the desktop you started from

**Method 2: From Tray Menu**
1. Right-click the tray icon
2. Select "Restore Layout" → Choose your profile

**Method 3: From Main Window**
1. Open Window Layout Manager
2. Select a profile from the list
3. Click "Restore Layout"

### 5. Setting Up Auto-Restore on Startup

1. Open Window Layout Manager from the tray
2. Scroll down to "Startup Settings" section
3. Select your preferred profile from "Default Profile" dropdown
4. Check "Auto-restore default profile on startup"
5. Next time you start Windows, your layout will automatically restore!

## User Interface

### Main Window

The main window provides full control over your profiles:

**Profile Management**:
- **Profile List**: Shows all saved profiles
- **New Profile**: Create a new layout profile (captures all desktops)
- **Edit Profile**: Modify profile settings, hotkey, and view captured windows
- **Duplicate Profile**: Create a copy of an existing profile
- **Delete Profile**: Remove a profile permanently
- **Export JSON**: Copy profile data to clipboard for sharing or backup

**Layout Operations**:
- **Restore Layout**: Apply the selected profile
- **Capture Current**: Update selected profile with current window arrangement

**Startup Settings**:
- **Run at Windows startup**: Enable/disable auto-start
- **Default Profile**: Select which profile to use by default
- **Auto-restore on startup**: Automatically restore default profile when Windows starts

### Profile Editor

When editing a profile, you can:
- Change the profile name
- Assign or modify the hotkey using the **Record Keys** button
- View all captured windows with their desktop assignments
- Recapture the current layout (preserves hotkey)

### System Tray Menu

Right-click the tray icon to access:
- Quick restore for all profiles (organized by submenu)
- Capture current layout
- Open settings window
- Refresh profiles
- About information
- Exit application

## Hotkey Format

Hotkeys use AutoHotkey syntax with these modifiers:

- `^` = Ctrl
- `!` = Alt
- `+` = Shift
- `#` = Win (Windows key)

### Examples:
- `^!1` = Ctrl + Alt + 1
- `#w` = Win + W
- `^+d` = Ctrl + Shift + D
- `!F1` = Alt + F1
- `Insert` = Insert key (no modifiers)

### Hotkey Best Practices:
- Use the **Record Keys** button for easy hotkey assignment
- Use Ctrl+Alt combinations for number keys (^!1 through ^!9)
- Avoid conflicts with existing Windows shortcuts
- Test hotkeys to ensure they work as expected

## Profile Storage

Profiles are stored as JSON files in:
```
%APPDATA%\WindowLayoutManager\Profiles\
```

Settings are stored in:
```
%APPDATA%\WindowLayoutManager\settings.json
```

Logs are stored in:
```
%APPDATA%\WindowLayoutManager\Logs\restore_YYYYMMDD_HHMMSS.log
```

Each profile contains:
- Profile name and metadata
- Assigned hotkey
- Creation and modification dates
- Array of window information (position, size, process, title, virtual desktop)

### Example Profile Structure:
```json
{
  "profileName": "Work Setup",
  "hotkey": "^!1",
  "createdDate": "20250117120000",
  "modifiedDate": "20250117120000",
  "windows": [
    {
      "processName": "chrome.exe",
      "windowTitle": "Gmail - Google Chrome",
      "x": 0,
      "y": 0,
      "width": 1280,
      "height": 1392,
      "hwnd": 123456,
      "desktop": 1,
      "maximized": 0,
      "minimized": 0,
      "executablePath": "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
    }
  ]
}
```

## Command Line Options

Run the application with these optional arguments:

```
WindowLayoutManager.exe [options]
```

### Options:
- `/restore <profile>` - Restore a specific profile by name
- `/minimize` - Start minimized to system tray
- `/help` - Show help information
- `/version` - Show version number

### Examples:
```batch
WindowLayoutManager.exe /restore "Work Setup"
WindowLayoutManager.exe /minimize
```

## Virtual Desktop Support

The application includes built-in support for Windows 11 virtual desktops:

- **Cross-Desktop Capture**: Automatically switches between desktops during capture to enumerate all windows
- **Desktop-Aware Restoration**: Moves windows to their saved virtual desktops using Win+Ctrl+Alt+Left/Right
- **Original Desktop Return**: After restoration, automatically returns to the desktop you started from
- **Multiple Desktop Support**: Supports layouts spanning multiple desktops (tested with Desktop 1 and 2)

### How It Works:
1. **Capture**: The app temporarily switches between desktops to capture all windows (takes ~6 seconds)
2. **Restore**: Windows are moved to their assigned desktops using keyboard shortcuts
3. **Return**: You're automatically returned to your original desktop

### Limitations:
- Desktop switching is briefly visible during capture and restore (Windows API limitation)
- Windows API only allows enumerating windows on the current desktop
- Some windows running with admin privileges may not be movable
- Maximum tested: 2 desktops (should support more)

## Troubleshooting

### Windows Don't Restore to Correct Position

**Problem**: Windows appear but aren't positioned correctly
**Solutions**:
- Ensure the application is running with standard user privileges
- Try recapturing the layout
- Check if the window allows programmatic positioning
- Verify the window isn't maximized when it should be restored

### Application Won't Launch Windows

**Problem**: Windows don't appear when restoring
**Solutions**:
- Verify executable paths are still valid
- Check that applications are installed in the same locations
- Edit the profile and recapture with current window arrangement
- For Windows Store apps (WhatsApp, Calculator, etc.): The app will automatically search shell:AppsFolder
- Check logs in %AppData%\WindowLayoutManager\Logs\ for detailed error information

### Hotkeys Don't Work

**Problem**: Pressing hotkey doesn't restore layout
**Solutions**:
- Check for conflicts with other applications
- Verify hotkey syntax is correct using the **Record Keys** button
- Ensure Window Layout Manager is running (check system tray)
- Try a different hotkey combination
- After editing a profile, hotkeys are automatically reloaded

### Virtual Desktop Issues

**Problem**: Windows don't move to correct desktop
**Solutions**:
- Allow the desktop switching process to complete (~6 seconds for capture)
- Ensure you have multiple desktops created (Win+Ctrl+D to create new desktop)
- Verify desktop numbers in the profile editor
- Try recapturing the layout while windows are on correct desktops

### Profile Loading Errors

**Problem**: "⚠ X profile(s) failed to load (corrupted JSON)"
**Solutions**:
- Check JSON syntax in profile files
- Restore from backup
- Delete corrupted profile files and recreate them
- The app will continue working with valid profiles

### Multiple Windows of Same App Not Restoring Correctly

**Problem**: Multiple Chrome/Terminal windows go to wrong positions
**Solutions**:
- The app uses window title matching to distinguish instances
- Make sure windows have unique titles when possible
- Restore order is based on title similarity scoring
- Each window is only positioned once per restore

## Advanced Usage

### Backup and Restore Profiles

**Backup**:
1. Navigate to `%APPDATA%\WindowLayoutManager\Profiles\`
2. Copy all `.json` files to a safe location
3. Optionally backup `settings.json` for your default profile setting

**Restore**:
1. Copy backed up `.json` files to profiles folder
2. Restart Window Layout Manager or click "Refresh Profiles" in tray menu

### Sharing Profiles

You can share profiles between computers using the Export JSON feature:
1. Select a profile in the main window
2. Click "Export JSON"
3. Profile data is copied to clipboard
4. Send to another computer
5. Save as `.json` file in their profiles folder
6. Edit executable paths if applications are in different locations

### Scripting and Automation

Call the application from scripts or Task Scheduler:
```batch
@echo off
REM Restore work layout
start "" "C:\Path\To\WindowLayoutManager.exe" /restore "Work Setup"
```

### Multiple Instances of Same Application

The application intelligently handles multiple windows of the same process:
- Matches windows by title similarity scoring
- Tracks which windows have been positioned to avoid duplicates
- Preserves instance order when possible
- Works great with multiple Chrome windows, VS Code windows, Terminal tabs, etc.

## Technical Details

### Architecture

- **Language**: AutoHotkey v2.0
- **Storage**: JSON files in AppData (UTF-8-RAW encoding, no BOM)
- **Virtual Desktop**: COM-based Windows API integration (IVirtualDesktopManager)
- **GUI Framework**: Native AHKv2 GUI with modern Windows 11 styling
- **Hotkeys**: Global system hotkeys with dynamic registration
- **Desktop Switching**: Win+Ctrl+Alt+Left/Right for moving windows between desktops

### Components

- `WindowLayoutManager.ahk` - Main entry point and application lifecycle
- `lib/VirtualDesktop.ahk` - Virtual desktop COM interface wrapper
- `lib/JSON.ahk` - JSON parser/serializer with UTF-8-RAW support
- `lib/WindowScanner.ahk` - Window enumeration and multi-desktop capture
- `lib/WindowRestorer.ahk` - Layout restoration engine with desktop awareness and UWP app support
- `lib/ProfileManager.ahk` - Profile CRUD operations and error handling
- `lib/SettingsManager.ahk` - Application settings and default profile management
- `lib/HotkeyManager.ahk` - Global hotkey registration and dynamic reload
- `lib/MainGUI.ahk` - Main application window with startup settings
- `lib/TrayMenu.ahk` - System tray integration with profile submenus
- `lib/ProgressIndicator.ahk` - Non-blocking progress window during restore operations
- `lib/Logger.ahk` - Timestamped logging for debugging and troubleshooting

### Excluded Windows

The following windows are automatically excluded from capture:
- System windows (taskbar, Start menu, Action Center, etc.)
- Shell windows (Program Manager, Windows.UI.Core.CoreWindow)
- Invisible windows (0x0 size or WS_EX_TOOLWINDOW style)
- Windows without valid titles
- NVIDIA Overlay and system overlays
- AutoHotkey/WindowLayoutManager itself
- Windows with specific excluded processes (wsl.exe helper windows, etc.)

### Unique Window Matching

When restoring, the app uses a sophisticated matching algorithm:
1. **Exact Match**: First tries exact window title match
2. **Similarity Score**: Calculates word-based similarity between titles
3. **Best Match**: Selects window with highest similarity score
4. **Used Window Tracking**: Maintains a Map of already-positioned windows
5. **Fallback**: Returns first unused window of the same process if no good match

This ensures multiple instances of the same application are positioned correctly.

## Known Limitations

1. **Desktop Switching Visibility**: Desktop switching during capture/restore is visible (Windows API limitation)
2. **Admin Windows**: Cannot move windows running with elevated privileges
3. **UWP App Names**: Store apps are matched by display name - if the app name changes, relaunch may fail
4. **Single Instance Apps**: Apps that only allow one instance may behave unexpectedly
5. **Desktop API Constraints**: Limited virtual desktop API access in Windows 11
6. **Window Size Limits**: Some applications enforce minimum/maximum sizes
7. **Background Desktop Operations**: Cannot enumerate windows on other desktops without switching to them

## FAQ

**Q: Can I use this on Windows 10?**
A: This is designed for Windows 11. Windows 10 has different virtual desktop APIs.

**Q: Will this work with dual monitors?**
A: Yes! Window positions include X/Y coordinates for multi-monitor setups.

**Q: Why does it switch desktops during capture?**
A: Windows API limitation - we can only enumerate windows on the current desktop.

**Q: Can I modify the JSON files directly?**
A: Yes, but be careful. Invalid JSON will cause errors (shown in GUI). Always backup first.

**Q: How many profiles can I create?**
A: Unlimited! Only limited by disk space.

**Q: Does this work with games?**
A: Most windowed games work. Fullscreen exclusive games won't be captured.

**Q: Can I export profiles?**
A: Yes, use the "Export JSON" button to copy profile data to clipboard.

**Q: How does the hotkey recorder work?**
A: It uses InputHook to capture your key press and automatically formats it in AutoHotkey syntax.

**Q: What happens if I have multiple Chrome windows?**
A: The app matches each window by title and tracks which windows have been positioned to avoid duplicates.

**Q: Can I disable auto-restore for a session?**
A: Yes, just uncheck "Auto-restore on startup" in the GUI. It's saved immediately.

## Contributing

This is an open-source project. Contributions are welcome!

### Areas for Improvement:
- True background desktop operations (would require Windows API changes)
- Support for saving/restoring monitor configurations
- Profile import GUI
- Layout templates and presets
- Advanced window filters and custom exclusions
- Scheduled profile restoration
- Window grouping and categories
- Profile encryption for security-sensitive layouts

## License

MIT License - Free to use, modify, and distribute.

## Support

For issues, questions, or feature requests:
- Check the troubleshooting section above
- Review the FAQ
- Create an issue on [GitHub](https://github.com/fullstacktard/windows-layout/issues)

## Version History

### v1.0.1 (Current - 2025-10-17)
**Improvements:**
- Added UWP/Windows Store app launching support (WhatsApp, Calculator, etc.)
- Replaced blocking MsgBox with non-blocking progress indicator window
- Fixed desktop filtering - windows are now only minimized on their own desktop
- Improved error handling - restore continues even if individual windows fail
- Added detailed logging to %AppData%\WindowLayoutManager\Logs\
- Progress indicator shows in taskbar with real-time status updates
- Enhanced error recovery in UWP app enumeration

### v1.0.0
- Initial release with full feature set
- Profile management (create, edit, delete, duplicate, export)
- Virtual desktop support with cross-desktop capture
- Desktop-aware restoration with return to original desktop
- Hotkey system with visual hotkey recorder
- Default profile and auto-restore on startup
- System tray integration with profile submenus
- Auto-start capability
- Window scanner with multi-desktop support
- Intelligent window restorer with duplicate prevention
- JSON-based storage with error handling
- Settings manager for persistent configuration
- Multiple instance handling for same applications

## Credits

- Built with AutoHotkey v2
- Windows Virtual Desktop API (IVirtualDesktopManager)
- Community feedback and testing

---

**Made with AutoHotkey v2**
Window Layout Manager - Save time, restore productivity
