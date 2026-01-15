/**
 * Window Layout Manager
 *
 * A Windows 11 desktop application that saves and restores window layouts
 * across multiple virtual desktops with custom hotkey support.
 *
 * This module provides programmatic access to launch the Window Layout Manager.
 * For CLI usage, use the `windows-layout` command.
 *
 * Supports both native Windows and WSL (Windows Subsystem for Linux) environments.
 *
 * @module @fullstacktard/windows-layout
 */

const { spawn, spawnSync, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

const packageDir = __dirname;
const exePath = path.join(packageDir, 'WindowLayoutManager.exe');

/**
 * Detect if running in WSL (Windows Subsystem for Linux)
 * @returns {boolean}
 */
function isWSL() {
  if (os.platform() !== 'linux') return false;

  try {
    const release = fs.readFileSync('/proc/version', 'utf8').toLowerCase();
    return release.includes('microsoft') || release.includes('wsl');
  } catch {
    return false;
  }
}

/**
 * Check if running on Windows (native or WSL)
 * @returns {boolean}
 */
function isWindows() {
  return os.platform() === 'win32' || isWSL();
}

/**
 * Convert WSL path to Windows path
 * @param {string} linuxPath
 * @returns {string}
 */
function toWindowsPath(linuxPath) {
  try {
    const result = execSync(`wslpath -w "${linuxPath}"`, { encoding: 'utf8' });
    return result.trim();
  } catch {
    if (linuxPath.startsWith('/mnt/')) {
      const parts = linuxPath.split('/');
      const drive = parts[2].toUpperCase();
      const rest = parts.slice(3).join('\\');
      return `${drive}:\\${rest}`;
    }
    const distro = getWSLDistro();
    return `\\\\wsl$\\${distro}${linuxPath.replace(/\//g, '\\')}`;
  }
}

/**
 * Get WSL distro name
 * @returns {string}
 */
function getWSLDistro() {
  try {
    const result = execSync('wsl.exe -l -q 2>/dev/null | head -1', { encoding: 'utf8' });
    return result.trim().replace(/\0/g, '') || 'Ubuntu';
  } catch {
    return 'Ubuntu';
  }
}

/**
 * Check if the executable exists
 * @returns {boolean}
 */
function executableExists() {
  return fs.existsSync(exePath);
}

/**
 * Launch executable via PowerShell (works with UNC paths in WSL)
 * @param {string} windowsExePath
 * @param {string[]} args
 * @returns {Promise<void>}
 */
function launchViaPowerShell(windowsExePath, args = []) {
  return new Promise((resolve, reject) => {
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
      reject(new Error(`Failed to launch via PowerShell: ${result.error.message}`));
    } else {
      resolve();
    }
  });
}

/**
 * Start Window Layout Manager
 * @param {Object} options - Launch options
 * @param {boolean} options.minimized - Start minimized to system tray
 * @param {boolean} options.autostart - Start with auto-restore enabled
 * @returns {Promise<void>}
 */
function start(options = {}) {
  return new Promise((resolve, reject) => {
    if (!isWindows()) {
      reject(new Error('Window Layout Manager only works on Windows 11 or WSL'));
      return;
    }

    if (!executableExists()) {
      reject(new Error(`Executable not found at: ${exePath}`));
      return;
    }

    const args = [];
    if (options.minimized) args.push('/minimize');
    if (options.autostart) args.push('/autostart');

    if (isWSL()) {
      // Running from WSL - use PowerShell to launch (handles UNC paths)
      const windowsExePath = toWindowsPath(exePath);
      launchViaPowerShell(windowsExePath, args).then(resolve).catch(reject);
    } else {
      // Running from Windows directly
      const child = spawn(exePath, args, {
        detached: true,
        stdio: 'ignore',
        windowsHide: false
      });
      child.unref();
      resolve();
    }
  });
}

/**
 * Restore a specific profile
 * @param {string} profileName - Name of the profile to restore
 * @returns {Promise<void>}
 */
function restore(profileName) {
  return new Promise((resolve, reject) => {
    if (!isWindows()) {
      reject(new Error('Window Layout Manager only works on Windows 11 or WSL'));
      return;
    }

    if (!executableExists()) {
      reject(new Error(`Executable not found at: ${exePath}`));
      return;
    }

    if (!profileName) {
      reject(new Error('Profile name is required'));
      return;
    }

    const args = ['/restore', profileName];

    if (isWSL()) {
      const windowsExePath = toWindowsPath(exePath);
      launchViaPowerShell(windowsExePath, args).then(resolve).catch(reject);
    } else {
      const child = spawn(exePath, args, {
        detached: true,
        stdio: 'ignore',
        windowsHide: false
      });
      child.unref();
      resolve();
    }
  });
}

/**
 * Get installation paths
 * @returns {Object}
 */
function getPaths() {
  const wsl = isWSL();
  const windowsExePath = wsl ? toWindowsPath(exePath) : null;

  return {
    packageDir,
    executable: exePath,
    executableWindows: windowsExePath,
    source: path.join(packageDir, 'WindowLayoutManager.ahk'),
    lib: path.join(packageDir, 'lib'),
    profiles: path.join(os.homedir(), 'AppData', 'Roaming', 'WindowLayoutManager', 'Profiles'),
    settings: path.join(os.homedir(), 'AppData', 'Roaming', 'WindowLayoutManager', 'settings.json'),
    logs: path.join(os.homedir(), 'AppData', 'Roaming', 'WindowLayoutManager', 'Logs'),
    isWSL: wsl
  };
}

module.exports = {
  start,
  restore,
  getPaths,
  isWindows,
  isWSL,
  executableExists
};
