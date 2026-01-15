#!/usr/bin/env node

const os = require('os');
const path = require('path');
const fs = require('fs');

const packageDir = path.join(__dirname, '..');
const exePath = path.join(packageDir, 'WindowLayoutManager.exe');

console.log(`
================================================================================
  Window Layout Manager v1.0.1 - Installation Complete
================================================================================

`);

if (os.platform() !== 'win32') {
  console.log(`  WARNING: This package only works on Windows 11.
  Current platform: ${os.platform()}

  If you're developing on a non-Windows system, you can still view
  and modify the source code, but the application won't run here.
`);
} else {
  const exeExists = fs.existsSync(exePath);

  console.log(`  Platform: Windows (compatible)
  Executable: ${exeExists ? 'Ready' : 'Not found - may need compilation'}

  Quick Start:
  ------------
  Run from command line:    windows-layout
  Start minimized:          windows-layout start --minimized
  Restore a profile:        windows-layout restore "Profile Name"
  Show help:                windows-layout help

  The application will appear in your system tray (bottom-right).
  Right-click the tray icon to access all features.

  Documentation:
  --------------
  Full README:    ${path.join(packageDir, 'README.md')}
  Quick Start:    ${path.join(packageDir, 'QUICKSTART.md')}
  Changelog:      ${path.join(packageDir, 'CHANGELOG.md')}
`);
}

console.log(`  Repository: https://github.com/fullstacktard/windows-layout
  Issues:     https://github.com/fullstacktard/windows-layout/issues

================================================================================
`);
