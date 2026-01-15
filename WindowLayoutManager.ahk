; ============================================================================
; Window Layout Manager v1.0
; ============================================================================
; A Windows 11 application to save and restore window layouts across
; multiple virtual desktops with hotkey support.
;
; Features:
; - Save/restore window positions and sizes
; - Virtual desktop support
; - Custom hotkeys for each profile
; - System tray integration
; - Auto-start capability
;
; Author: Window Layout Manager Team
; License: MIT
; ============================================================================

#Requires AutoHotkey v2.0+
#SingleInstance Force

; Set process priority
ProcessSetPriority("High")

; Include all required libraries
#Include lib\VirtualDesktop.ahk
#Include lib\JSON.ahk
#Include lib\WindowScanner.ahk
#Include lib\WindowRestorer.ahk
#Include lib\ProfileManager.ahk
#Include lib\SettingsManager.ahk
#Include lib\HotkeyManager.ahk
#Include lib\MainGUI.ahk
#Include lib\TrayMenu.ahk

; ============================================================================
; Application Class
; ============================================================================

class WindowLayoutApp {
    static version := "1.0.1"
    static appName := "Window Layout Manager"
    static initialized := false

    ; Initialize the application
    static Initialize() {
        if (this.initialized) {
            return
        }

        ; Set up error handling
        try {
            ; Initialize settings manager
            SettingsManager.__New()

            ; Initialize profile manager
            ProfileManager.__New()

            ; Initialize hotkey manager
            HotkeyManager.Initialize()

            ; Initialize tray menu
            TrayMenu.Initialize()

            ; Check command line arguments and handle auto-start
            autoStart := this.HandleCommandLine()

            ; Always start minimized to tray
            A_IconTip := this.appName . " - Running in background"

            this.initialized := true

            ; Show startup notification
            this.ShowStartupNotification()

            ; Auto-restore default profile only if launched with /autostart flag
            if (autoStart) {
                this.AutoRestoreOnStartup()
            }

        } catch as e {
            MsgBox("Failed to initialize application:`n`n" . e.Message, "Error", "Icon!")
            ExitApp()
        }
    }

    ; Handle command line arguments
    static HandleCommandLine() {
        ; Check for command line arguments
        if (A_Args.Length > 0) {
            command := A_Args[1]

            switch command {
                case "/autostart":
                    ; Launched on Windows startup - enable auto-restore
                    return true

                case "/restore":
                    ; Restore a specific profile
                    if (A_Args.Length > 1) {
                        profileName := A_Args[2]
                        this.RestoreProfile(profileName)
                    }
                    return false

                case "/minimize":
                    ; Start minimized
                    return false

                case "/help", "/?":
                    this.ShowHelp()
                    ExitApp()

                case "/version":
                    MsgBox(this.appName . " v" . this.version, "Version", "Icon")
                    ExitApp()

                default:
                    ; Unknown argument
                    MsgBox("Unknown command: " . command . "`n`nUse /help for usage information.", "Error", "Icon!")
                    return false
            }
        }
        return false  ; No auto-start by default
    }

    ; Restore a profile by name
    static RestoreProfile(profileName) {
        try {
            profile := ProfileManager.LoadProfile(profileName)

            if (!profile) {
                MsgBox("Profile '" . profileName . "' not found!", "Error", "Icon!")
                return
            }

            windows := profile["windows"]
            result := WindowRestorer.RestoreLayout(windows)

            ; Build notification message
            message := Format("Restored: {} | Failed: {}", result.restored, result.failed)
            if (result.Has("minimized") && result.minimized > 0) {
                message .= Format(" | Minimized: {}", result.minimized)
            }

            TrayMenu.ShowNotification("Layout Restored", message)
        } catch as e {
            MsgBox("Error restoring profile: " . e.Message, "Error", "Icon!")
        }
    }

    ; Show startup notification
    static ShowStartupNotification() {
        ; Silent startup - no tooltips
    }

    ; Auto-restore default profile on startup (disabled)
    static AutoRestoreOnStartup() {
        ; Auto-restore on startup is disabled
        ; Use hotkeys to manually restore profiles
        return
    }

    ; Show help
    static ShowHelp() {
        helpText := this.appName . " v" . this.version . "`n`n"
        helpText .= "Usage:`n"
        helpText .= "  WindowLayoutManager.exe [options]`n`n"
        helpText .= "Options:`n"
        helpText .= "  /restore <profile>  - Restore a specific profile`n"
        helpText .= "  /minimize          - Start minimized to tray`n"
        helpText .= "  /help              - Show this help`n"
        helpText .= "  /version           - Show version information`n`n"
        helpText .= "Features:`n"
        helpText .= "  - Save and restore window layouts`n"
        helpText .= "  - Virtual desktop support`n"
        helpText .= "  - Custom hotkeys`n"
        helpText .= "  - System tray integration`n"

        MsgBox(helpText, "Help - " . this.appName, "Icon")
    }

    ; Shutdown the application
    static Shutdown() {
        try {
            ; Unregister all hotkeys
            HotkeyManager.UnregisterAllHotkeys()

            ; Destroy GUI
            MainGUI.Destroy()

            ; Exit
            ExitApp()
        } catch {
            ExitApp()
        }
    }

    ; Reload the application
    static Reload() {
        Reload()
    }
}

; ============================================================================
; Application Entry Point
; ============================================================================

; Set up persistent script
Persistent(true)

; Initialize the application
WindowLayoutApp.Initialize()

; ============================================================================
; Global Hotkeys (Optional - for debugging)
; ============================================================================

; Uncomment for debugging
; ^!r:: WindowLayoutApp.Reload()  ; Ctrl+Alt+R to reload

; ============================================================================
; Exit Handler
; ============================================================================

OnExit((*) => WindowLayoutApp.Shutdown())

; ============================================================================
; End of Script
; ============================================================================
