# Changelog

All notable changes to the Window Layout Manager restoration system.

## [Version 4.1] - 2025-10-17

### Added
- **Step 0: Pre-Restoration Window Movement** - Moves windows from wrong desktops BEFORE detection/matching
  - Scans all desktops for windows that belong elsewhere
  - Uses VirtualDesktop DLL API for reliable window moving
  - Tracks moved windows to prevent re-launching

- **Hidden Window Detection** - Finds minimized/hidden apps
  - Telegram.exe windows (including system tray)
  - ApplicationFrameHost.exe (WhatsApp and other UWP apps)
  - Docker Desktop background windows

- **Smart Window Matching**
  - Process-based matching for single-window apps (Telegram, Docker, Claude, Spotify, Evernote)
  - Title-based matching for multi-window apps (Chrome, Terminal, VSCode)
  - Special Telegram matching: "Telegram (42704)" matches "TelegramDesktop"
  - Flexible title matching: exact, contains, reverse contains

- **Moved Window Tracking**
  - `movedHwnds` Map tracks windows moved in Step 0
  - Forces moved windows to "reposition" action (prevents launching duplicates)
  - Ignores position score for moved windows

- **Enhanced Debug Logging**
  - Step 0: Shows what windows are being searched for
  - Step 0: Shows found window counts (including hidden)
  - Step 0: Shows desktop numbers and matching decisions
  - Step B: Logs when moved windows are being repositioned

### Changed
- **Window Moving Method** - Replaced keyboard shortcuts with DLL API
  - Old: `Send("#^{Right}")` - only switches desktops, doesn't move windows ❌
  - New: `VirtualDesktop.MoveWindowToDesktop(hwnd, desktopNum)` - actually moves windows ✅

- **Timeout Increases**
  - Global timeout: 30s → 90s
  - Per-desktop launch timeout: 30s → 90s
  - Step 0 settle time: 200ms → 500ms

- **ApplicationFrameHost Handling**
  - Removed from single-window app list (it's used by ALL UWP apps)
  - Now matches by title for WhatsApp and other UWP apps
  - Detects hidden windows for minimized UWP apps

### Fixed
- **WhatsApp not resizing after move**
  - Removed `usedHwnds` marking in Step 0
  - Windows now properly matched and positioned in Steps B & D

- **Telegram/WhatsApp not moving between desktops**
  - Implemented Step 0 with DLL API
  - Added hidden window detection
  - Added flexible title matching

- **QTrayIcon and hidden system windows appearing**
  - Filter QTrayIcon, Default IME, GDI+ Window, MSCTFIME UI
  - Applied filters in 3 locations: Step 0, Launch phase, Docker detection

- **Duplicate windows being launched**
  - Track moved windows in `movedHwnds` Map
  - Force "reposition" action for moved windows regardless of score

- **Toast notifications not showing**
  - Added missing `ToastNotification.Info()` method

- **Docker black box appearing**
  - Filter out Docker system windows (GDI+, QTrayIcon)
  - Only show Docker Dashboard window

### Security
- No changes

### Removed
- Keyboard-based window moving (`#^{Left}`, `#^{Right}`)
- `chrome.exe` from single-window apps list (can have multiple windows)
- Marking windows as "used" in Step 0

---

## [Version 4.0] - Earlier

### Added
- Desktop-by-desktop restoration (process each desktop sequentially)
- VirtualDesktop DLL integration
- Window matching by position proximity
- Fast polling window detection (10x50ms)
- Fallback 5-second polling for slow apps
- Hidden window detection for Docker Desktop
- Loading GUI with progress indicator
- Toast notifications for completion

### Changed
- Switched from simultaneous desktop processing to sequential
- Launch apps on target desktop instead of moving after launch
- Improved Chrome launch (--profile-directory=Default)
- Windows Terminal force new window (-w -1)

### Fixed
- Various window detection issues
- Timeout handling
- Hidden window management

---

## Migration Notes

### Upgrading from Version 4.0 to 4.1

No profile changes needed! Your existing profiles will work with the new restoration logic.

**What happens automatically**:
1. Windows on wrong desktops are moved BEFORE restoration starts
2. Telegram title changes are handled automatically
3. Hidden/minimized WhatsApp is now detected
4. No duplicate windows will be launched

**Recommended**:
- Re-capture your profile if you have Telegram windows (to get accurate titles)
- Check logs after first restoration to verify Step 0 is working
- Report any issues with window matching to the development team

---

## Debug Log Changes

### New Log Messages (Version 4.1)

```
[INFO] Step 0: Checking for windows that belong on desktop X but are elsewhere
[DEBUG] Step 0: Looking for 'WhatsApp' (process: ApplicationFrameHost.exe)
[DEBUG] Step 0: Found X windows (including hidden) for process Y
[DEBUG] Step 0: HWND X - Title: 'Y' - Desktop: Z - Target: W
[INFO] MOVING (process match): Window from desktop X to desktop Y
[INFO] MOVING (title match): Window from desktop X to desktop Y
[INFO] MOVING (Telegram match): TelegramDesktop from desktop X to desktop Y
[INFO] ✓ Moved Window to desktop X (will be positioned later)
[INFO] Planning REPOSITION for MOVED window: X (score: Y - ignoring score)
```

### Removed Log Messages

```
[DEBUG] Sending Win+Ctrl+Right (iteration X of Y)
[DEBUG] Sending Win+Ctrl+Left (iteration X of Y)
```

---

**Version History**:
- 4.1 (2025-10-17): Step 0 implementation, hidden window detection, moved window tracking
- 4.0 (Earlier): Desktop-by-desktop restoration, VirtualDesktop DLL integration
