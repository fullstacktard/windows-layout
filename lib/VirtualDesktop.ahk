; Virtual Desktop Manager for Windows 11
; Uses VirtualDesktopAccessor.dll for reliable virtual desktop operations
#Include Logger.ahk

class VirtualDesktop {
    static hModule := 0
    static fnMoveWindowToDesktopNumber := 0
    static fnGetDesktopCount := 0
    static fnGetCurrentDesktopNumber := 0
    static fnGoToDesktopNumber := 0
    static fnGetWindowDesktopNumber := 0
    static fnIsWindowOnCurrentVirtualDesktop := 0

    ; Initialize DLL
    static __New() {
        try {
            ; Get the path to the DLL
            dllPath := A_ScriptDir . "\lib\VirtualDesktopAccessor\VirtualDesktopAccessor.dll"

            ; Convert to Windows path
            dllPath := StrReplace(dllPath, "/", "\")

            Logger.Info(Format("Loading VirtualDesktopAccessor.dll from: {}", dllPath))

            ; Load the DLL
            this.hModule := DllCall("LoadLibrary", "Str", dllPath, "Ptr")

            if (!this.hModule) {
                throw Error("Failed to load VirtualDesktopAccessor.dll")
            }

            Logger.Info("DLL loaded successfully")

            ; Get function pointers
            this.fnMoveWindowToDesktopNumber := DllCall("GetProcAddress", "Ptr", this.hModule, "AStr", "MoveWindowToDesktopNumber", "Ptr")
            this.fnGetDesktopCount := DllCall("GetProcAddress", "Ptr", this.hModule, "AStr", "GetDesktopCount", "Ptr")
            this.fnGetCurrentDesktopNumber := DllCall("GetProcAddress", "Ptr", this.hModule, "AStr", "GetCurrentDesktopNumber", "Ptr")
            this.fnGoToDesktopNumber := DllCall("GetProcAddress", "Ptr", this.hModule, "AStr", "GoToDesktopNumber", "Ptr")
            this.fnGetWindowDesktopNumber := DllCall("GetProcAddress", "Ptr", this.hModule, "AStr", "GetWindowDesktopNumber", "Ptr")
            this.fnIsWindowOnCurrentVirtualDesktop := DllCall("GetProcAddress", "Ptr", this.hModule, "AStr", "IsWindowOnCurrentVirtualDesktop", "Ptr")

            if (!this.fnMoveWindowToDesktopNumber || !this.fnGetDesktopCount || !this.fnGetCurrentDesktopNumber) {
                throw Error("Failed to get DLL function pointers")
            }

            Logger.Info("All DLL functions loaded successfully")
        } catch as e {
            Logger.Error(Format("Error initializing Virtual Desktop Manager: {}", e.Message))
            MsgBox("Error initializing Virtual Desktop Manager: " . e.Message . "`n`nPlease ensure VirtualDesktopAccessor.dll is in the lib folder.")
        }
    }

    ; Get the desktop number for a window (1-indexed)
    ; Note: DLL returns 0-indexed, we convert to 1-indexed
    static GetDesktopNumber(hwnd) {
        try {
            if (!this.fnGetWindowDesktopNumber) {
                Logger.Error("GetWindowDesktopNumber function not loaded")
                return 1
            }

            Logger.Debug(Format("Getting desktop number for window HWND: {}", hwnd))

            ; Call the DLL function (returns 0-indexed)
            desktopNum := DllCall(this.fnGetWindowDesktopNumber, "Ptr", hwnd, "Int")

            ; Convert to 1-indexed
            result := desktopNum + 1

            Logger.Debug(Format("Window is on desktop {} (DLL returned {})", result, desktopNum))
            return result
        } catch as e {
            Logger.Error(Format("Error getting desktop number: {}", e.Message))
            return 1
        }
    }

    ; Check if window is on current virtual desktop
    static IsWindowOnCurrentVirtualDesktop(hwnd) {
        try {
            if (!this.fnIsWindowOnCurrentVirtualDesktop) {
                return -1
            }

            result := DllCall(this.fnIsWindowOnCurrentVirtualDesktop, "Ptr", hwnd, "Int")
            return result  ; Returns 1 (true) or 0 (false)
        } catch as e {
            Logger.Error(Format("Error checking if window on current desktop: {}", e.Message))
            return -1
        }
    }

    ; Move window to desktop number (1-indexed)
    ; Returns true on success, false on failure
    static MoveWindowToDesktop(hwnd, desktopNum) {
        try {
            if (!this.fnMoveWindowToDesktopNumber) {
                Logger.Error("MoveWindowToDesktopNumber function not loaded")
                return false
            }

            ; Convert from 1-indexed to 0-indexed for DLL
            desktopIndex := desktopNum - 1

            Logger.Debug(Format("Moving window HWND {} to desktop {} (DLL index {})", hwnd, desktopNum, desktopIndex))

            ; Call the DLL function
            ; Returns BOOL (1 for success, 0 for failure)
            result := DllCall(this.fnMoveWindowToDesktopNumber, "Ptr", hwnd, "Int", desktopIndex, "Int")

            if (result) {
                Logger.Debug(Format("Successfully moved window to desktop {}", desktopNum))
                return true
            } else {
                Logger.Warn(Format("Failed to move window to desktop {}", desktopNum))
                return false
            }
        } catch as e {
            Logger.Error(Format("Error moving window to desktop: {}", e.Message))
            return false
        }
    }

    ; Get current desktop number (1-indexed)
    ; Note: DLL returns 0-indexed, we convert to 1-indexed
    static GetCurrentDesktopNumber() {
        try {
            if (!this.fnGetCurrentDesktopNumber) {
                Logger.Error("GetCurrentDesktopNumber function not loaded")
                return 1
            }

            ; Call the DLL function (returns 0-indexed)
            desktopNum := DllCall(this.fnGetCurrentDesktopNumber, "Int")

            ; Convert to 1-indexed
            result := desktopNum + 1

            Logger.Debug(Format("Current desktop is {} (DLL returned {})", result, desktopNum))
            return result
        } catch as e {
            Logger.Error(Format("Error getting current desktop number: {}", e.Message))
            return 1
        }
    }

    ; Get total number of desktops
    static GetDesktopCount() {
        try {
            if (!this.fnGetDesktopCount) {
                Logger.Error("GetDesktopCount function not loaded")
                return 4
            }

            count := DllCall(this.fnGetDesktopCount, "Int")
            Logger.Debug(Format("Total virtual desktops: {}", count))
            return count
        } catch as e {
            Logger.Error(Format("Error getting desktop count: {}", e.Message))
            return 4
        }
    }

    ; Switch to desktop number (1-indexed)
    static SwitchToDesktop(desktopNum) {
        try {
            if (!this.fnGoToDesktopNumber) {
                Logger.Error("GoToDesktopNumber function not loaded")
                return false
            }

            ; Convert from 1-indexed to 0-indexed for DLL
            desktopIndex := desktopNum - 1

            Logger.Debug(Format("Switching to desktop {} (DLL index {})", desktopNum, desktopIndex))

            ; Call the DLL function (void return, no return value to check)
            DllCall(this.fnGoToDesktopNumber, "Int", desktopIndex)

            ; Give Windows a moment to complete the switch
            Sleep(150)
            return true
        } catch as e {
            Logger.Error(Format("Error switching to desktop: {}", e.Message))
            return false
        }
    }

    ; Create a new desktop
    static CreateDesktop() {
        try {
            Send("^#d")
            Sleep(500)
            return true
        } catch {
            return false
        }
    }
}
