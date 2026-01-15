# Quick Start Guide

Get started with Window Layout Manager in 5 minutes!

## Installation

### Option 1: Run the Script
1. Install [AutoHotkey v2](https://www.autohotkey.com/download/)
2. Double-click `WindowLayoutManager.ahk`

### Option 2: Use Compiled Version
1. Right-click `WindowLayoutManager.ahk` → "Compile Script"
2. Run the generated `WindowLayoutManager.exe`

## Basic Usage

### Save Your First Layout

1. **Arrange your windows**
   - Open all applications you want to save
   - Position them across your virtual desktops
   - Resize and arrange as desired

2. **Capture the layout**
   - Right-click the tray icon
   - Select "Capture Current Layout"
   - Enter a name (e.g., "My Work Setup")
   - Click OK

3. **Done!** Your layout is saved

### Restore a Layout

**Method 1: Tray Menu**
- Right-click tray icon → "Restore Layout" → Select your profile

**Method 2: Hotkey** (Recommended)
1. Right-click tray icon → "Open Settings"
2. Select your profile → Click "Edit Profile"
3. Enter a hotkey (e.g., `^!1` for Ctrl+Alt+1)
4. Click "Save Changes"
5. Press your hotkey anytime to restore!

## Common Hotkeys

Format: `Modifier+Key`

**Modifiers:**
- `^` = Ctrl
- `!` = Alt
- `+` = Shift
- `#` = Win

**Examples:**
- `^!1` = Ctrl + Alt + 1 (recommended for profile 1)
- `^!2` = Ctrl + Alt + 2 (recommended for profile 2)
- `#w` = Win + W
- `+F1` = Shift + F1

## Example Workflow

### For Developers

**Save "Coding" Layout:**
1. Desktop 1: Browser (left) + Documentation (right)
2. Desktop 2: VS Code (maximized)
3. Desktop 3: Terminal windows
4. Capture as "Coding" with hotkey `^!1`

**Save "Debugging" Layout:**
1. Desktop 1: Browser with localhost
2. Desktop 2: VS Code + DevTools side-by-side
3. Desktop 3: Logs and database tools
4. Capture as "Debugging" with hotkey `^!2`

**Switching:**
- Press `Ctrl+Alt+1` → Instant coding setup
- Press `Ctrl+Alt+2` → Instant debugging setup

### For Students

**Save "Study" Layout:**
1. Desktop 1: Course materials + notepad
2. Desktop 2: Research browser tabs
3. Desktop 3: Video lecture fullscreen
4. Capture as "Study" with hotkey `^!s`

### For Streamers

**Save "Streaming" Layout:**
1. Desktop 1: OBS + Chat
2. Desktop 2: Game (windowed)
3. Desktop 3: Music + Discord
4. Capture as "Streaming" with hotkey `^!t`

## Tips & Tricks

1. **Multiple Profiles**: Create different profiles for different tasks
2. **Quick Switch**: Use number hotkeys (^!1, ^!2, etc.) for fast switching
3. **Update Layouts**: Select profile → "Capture Current" to update
4. **Backup**: Profiles saved in `%APPDATA%\WindowLayoutManager\Profiles\`
5. **Auto-Start**: Enable in settings to run at Windows startup

## Common Tasks

### Duplicate a Profile
1. Open Settings
2. Select profile → "Duplicate Profile"
3. Enter new name
4. Modify as needed

### Update Existing Profile
1. Arrange windows as desired
2. Open Settings
3. Select profile → "Capture Current"
4. Confirm update

### Delete a Profile
1. Open Settings
2. Select profile → "Delete Profile"
3. Confirm deletion

### Change Hotkey
1. Open Settings
2. Select profile → "Edit Profile"
3. Change hotkey field
4. Save changes

## Troubleshooting

**Windows don't restore?**
- Make sure applications are installed
- Check if profile was captured correctly
- Try recapturing the layout

**Hotkey doesn't work?**
- Check for conflicts with other software
- Try a different hotkey combination
- Ensure app is running in tray

**Can't find tray icon?**
- Click the arrow in system tray to show hidden icons
- Check if app is running in Task Manager

## Next Steps

- Read the full [README.md](README.md) for detailed features
- See [COMPILE.md](COMPILE.md) to create a standalone .exe
- Experiment with different layouts!

---

**Need Help?** Check README.md for detailed documentation.
