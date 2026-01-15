#!/usr/bin/env node

const { spawn, spawnSync, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

const packageDir = path.join(__dirname, '..');
const exePath = path.join(packageDir, 'WindowLayoutManager.exe');
const ahkPath = path.join(packageDir, 'WindowLayoutManager.ahk');

/**
 * Detect if running in WSL (Windows Subsystem for Linux)
 */
function isWSL() {
  if (os.platform() !== 'linux') return false;

  try {
    // Check for WSL-specific indicators
    const release = fs.readFileSync('/proc/version', 'utf8').toLowerCase();
    return release.includes('microsoft') || release.includes('wsl');
  } catch {
    return false;
  }
}

/**
 * Convert WSL path to Windows path
 */
function toWindowsPath(linuxPath) {
  try {
    const result = execSync(`wslpath -w "${linuxPath}"`, { encoding: 'utf8' });
    return result.trim();
  } catch {
    // Fallback: manual conversion for /mnt/c style paths
    if (linuxPath.startsWith('/mnt/')) {
      const parts = linuxPath.split('/');
      const drive = parts[2].toUpperCase();
      const rest = parts.slice(3).join('\\');
      return `${drive}:\\${rest}`;
    }
    // For paths in WSL filesystem, use \\wsl$ UNC path
    const distro = getWSLDistro();
    return `\\\\wsl$\\${distro}${linuxPath.replace(/\//g, '\\')}`;
  }
}

/**
 * Get WSL distro name
 */
function getWSLDistro() {
  try {
    const result = execSync('wsl.exe -l -q 2>/dev/null | head -1', { encoding: 'utf8' });
    return result.trim().replace(/\0/g, '') || 'Ubuntu';
  } catch {
    return 'Ubuntu';
  }
}

function printHelp() {
  const wslNote = isWSL() ? `
Environment:
  Running in WSL - will use Windows interop to launch the application.
` : '';

  console.log(`
Window Layout Manager v1.0.4

A Windows 11 desktop application that saves and restores window layouts
across multiple virtual desktops with custom hotkey support.

Usage:
  windows-layout [command] [options]

Commands:
  start              Start Window Layout Manager (default)
  restore <profile>  Restore a specific profile by name
  help               Show this help message
  version            Show version number
  info               Show installation info and paths

Options:
  --minimized        Start minimized to system tray
  --autostart        Start with auto-restore enabled

Examples:
  windows-layout                        Start the application
  windows-layout start --minimized      Start minimized to tray
  windows-layout restore "Work Setup"   Restore a specific profile
  windows-layout info                   Show installation paths

Requirements:
  - Windows 11 (build 22000 or later)
  - AutoHotkey v2.0+ (for running from source)
    OR
  - Use the pre-compiled .exe (included)
${wslNote}
Documentation:
  https://github.com/fullstacktard/windows-layout
`);
}

function printVersion() {
  const pkg = require('../package.json');
  console.log(`Window Layout Manager v${pkg.version}`);
}

function printInfo() {
  const wsl = isWSL();
  const windowsExePath = wsl ? toWindowsPath(exePath) : exePath;

  console.log(`
Window Layout Manager - Installation Info

Platform:          ${os.platform()}${wsl ? ' (WSL - Windows interop available)' : ''}
Package directory: ${packageDir}
Executable path:   ${exePath}
${wsl ? `Windows path:      ${windowsExePath}` : ''}
Source path:       ${ahkPath}

Executable exists: ${fs.existsSync(exePath) ? 'Yes' : 'No'}
Source exists:     ${fs.existsSync(ahkPath) ? 'Yes' : 'No'}

Profile storage:   %APPDATA%\\WindowLayoutManager\\Profiles\\
Settings file:     %APPDATA%\\WindowLayoutManager\\settings.json
Log files:         %APPDATA%\\WindowLayoutManager\\Logs\\

To run from source, you need AutoHotkey v2.0+ installed:
  https://www.autohotkey.com/download/
`);
}

function checkPlatform() {
  const platform = os.platform();
  const wsl = isWSL();

  if (platform !== 'win32' && !wsl) {
    console.error('Error: Window Layout Manager only works on Windows 11 or WSL.');
    console.error('Current platform:', platform);
    process.exit(1);
  }
}

function runExecutable(args = []) {
  checkPlatform();

  if (!fs.existsSync(exePath)) {
    console.error('Error: WindowLayoutManager.exe not found.');
    console.error('Expected path:', exePath);
    console.error('\nYou can compile from source using AutoHotkey v2:');
    console.error('  1. Install AutoHotkey v2 from https://www.autohotkey.com/download/');
    console.error('  2. Right-click WindowLayoutManager.ahk and select "Compile Script"');
    process.exit(1);
  }

  const wsl = isWSL();

  if (wsl) {
    // Running from WSL - use PowerShell to launch (handles UNC paths properly)
    const windowsExePath = toWindowsPath(exePath);
    console.log('Detected WSL environment. Launching via Windows interop...');
    console.log(`Windows path: ${windowsExePath}`);

    // Build PowerShell command with arguments
    let psCommand = `Start-Process -FilePath '${windowsExePath}'`;
    if (args.length > 0) {
      const argsStr = args.map(a => `'${a}'`).join(',');
      psCommand += ` -ArgumentList ${argsStr}`;
    }

    // Use spawnSync to ensure PowerShell completes the Start-Process
    const result = spawnSync('powershell.exe', ['-Command', psCommand], {
      stdio: 'ignore',
      windowsHide: false
    });

    if (result.error) {
      console.error('Failed to launch:', result.error.message);
      console.error('\nTry running directly from Windows:');
      console.error(`  ${windowsExePath}`);
      process.exit(1);
    }

    console.log('Window Layout Manager started. Check your Windows system tray.');
  } else {
    // Running from Windows directly
    console.log('Starting Window Layout Manager...');

    const child = spawn(exePath, args, {
      detached: true,
      stdio: 'ignore',
      windowsHide: false
    });

    child.unref();
    console.log('Window Layout Manager started. Check your system tray.');
  }
}

function main() {
  const args = process.argv.slice(2);
  const command = args[0] || 'start';

  switch (command.toLowerCase()) {
    case 'help':
    case '--help':
    case '-h':
      printHelp();
      break;

    case 'version':
    case '--version':
    case '-v':
      printVersion();
      break;

    case 'info':
    case '--info':
      printInfo();
      break;

    case 'start':
      const startArgs = [];
      if (args.includes('--minimized')) {
        startArgs.push('/minimize');
      }
      if (args.includes('--autostart')) {
        startArgs.push('/autostart');
      }
      runExecutable(startArgs);
      break;

    case 'restore':
      if (!args[1]) {
        console.error('Error: Profile name required.');
        console.error('Usage: windows-layout restore "Profile Name"');
        process.exit(1);
      }
      runExecutable(['/restore', args[1]]);
      break;

    default:
      // If no recognized command, try to start with the argument as-is
      if (command.startsWith('-') || command.startsWith('/')) {
        runExecutable(args);
      } else {
        console.error(`Unknown command: ${command}`);
        console.error('Run "windows-layout help" for usage information.');
        process.exit(1);
      }
  }
}

main();
