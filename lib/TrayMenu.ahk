; System Tray Menu Manager
#Include ProfileManager.ahk
#Include MainGUI.ahk

class TrayMenu {
    static mainMenu := ""

    ; Initialize system tray
    static Initialize() {
        ; Set tray icon tooltip
        A_IconTip := "Window Layout Manager"

        ; Set double-click action to open GUI
        A_IconHidden := false

        ; Add event handler for tray icon click
        A_TrayMenu.ClickCount := 1

        ; Create tray menu
        this.BuildMenu()

        ; Set default action after menu is built
        try {
            A_TrayMenu.Default := "Open Settings"
        }
    }

    ; Build the tray menu
    static BuildMenu() {
        ; Clear existing tray menu
        try {
            while (A_TrayMenu.Count > 0) {
                A_TrayMenu.Delete("1&")
            }
        } catch {
            ; Menu already empty or error
        }

        ; Add title (disabled item)
        A_TrayMenu.Add("Window Layout Manager", (*) => "")
        A_TrayMenu.Disable("Window Layout Manager")
        A_TrayMenu.Add() ; Separator

        ; Add profile section
        profiles := ProfileManager.GetProfileNames()

        if (profiles.Length > 0) {
            ; Add profiles submenu
            profilesMenu := Menu()

            for profileName in profiles {
                ; Create menu item with closure to capture profileName
                profilesMenu.Add(profileName, this.CreateRestoreHandler(profileName))
            }

            A_TrayMenu.Add("Restore Layout", profilesMenu)
            A_TrayMenu.Add() ; Separator
        } else {
            A_TrayMenu.Add("No Profiles Available", (*) => "")
            A_TrayMenu.Disable("No Profiles Available")
            A_TrayMenu.Add() ; Separator
        }

        ; Add quick actions
        A_TrayMenu.Add("Capture Current Layout", (*) => this.CaptureLayout())
        A_TrayMenu.Add() ; Separator

        ; Add main window option
        A_TrayMenu.Add("Open Settings", (*) => this.OpenSettings())

        ; Add refresh option
        A_TrayMenu.Add("Refresh Profiles", (*) => this.RefreshMenu())

        A_TrayMenu.Add() ; Separator

        ; Add about
        A_TrayMenu.Add("About", (*) => this.ShowAbout())

        ; Add exit
        A_TrayMenu.Add("Exit", (*) => this.ExitApp())
    }

    ; Create a restore handler for a specific profile
    static CreateRestoreHandler(profileName) {
        return (*) => this.RestoreProfile(profileName)
    }

    ; Restore a profile from tray menu
    static RestoreProfile(profileName) {
        try {
            profile := ProfileManager.LoadProfile(profileName)

            if (!profile) {
                MsgBox("Failed to load profile!", "Error", "Icon!")
                return
            }

            windows := profile["windows"]

            if (windows.Length = 0) {
                MsgBox("This profile has no windows to restore!", "Warning", "Icon!")
                return
            }

            ; Restore layout (GUI will show during restoration)
            result := WindowRestorer.RestoreLayout(windows)

            ; Notification sent by WindowRestorer
        } catch as e {
            MsgBox("Error restoring layout: " . e.Message, "Error", "Icon!")
        }
    }

    ; Capture current layout
    static CaptureLayout() {
        ; Prompt for profile name
        ib := InputBox("Enter a name for this layout:", "Capture Layout", "w300 h150")

        if (ib.Result = "OK" && ib.Value != "") {
            profileName := ib.Value

            ; Check if profile exists
            if (ProfileManager.ProfileExists(profileName)) {
                result := MsgBox("Profile '" . profileName . "' already exists. Overwrite?",
                                "Profile Exists", "YesNo Icon?")

                if (result != "Yes") {
                    return
                }
            }

            ; Scan windows
            windows := WindowScanner.ScanAllWindows()

            if (windows.Length = 0) {
                MsgBox("No windows found to capture!", "Warning", "Icon!")
                return
            }

            ; Save profile
            result := ProfileManager.SaveProfile(profileName, windows, "")

            if (result) {
                MsgBox("Profile '" . profileName . "' saved with " . windows.Length . " windows!", "Success", "Icon")

                ; Refresh menu
                this.RefreshMenu()
            } else {
                MsgBox("Failed to save profile!", "Error", "Icon!")
            }
        }
    }

    ; Open settings window
    static OpenSettings() {
        if (MainGUI.window) {
            MainGUI.RestoreFromTray()
        } else {
            MainGUI.Show()
        }
    }

    ; Refresh the tray menu
    static RefreshMenu() {
        ; Rebuild the menu with updated profiles
        this.BuildMenu()

        ; Silent refresh - no tooltips
    }

    ; Show about dialog
    static ShowAbout() {
        aboutText := "Window Layout Manager v1.0`n`n"
        aboutText .= "Save and restore window layouts across virtual desktops.`n`n"
        aboutText .= "Features:`n"
        aboutText .= "- Multiple layout profiles`n"
        aboutText .= "- Virtual desktop support`n"
        aboutText .= "- Custom hotkeys`n"
        aboutText .= "- Auto-restore on startup`n`n"
        aboutText .= "Built with AutoHotkey v2"

        MsgBox(aboutText, "About Window Layout Manager", "Icon")
    }

    ; Exit application
    static ExitApp() {
        result := MsgBox("Are you sure you want to exit Window Layout Manager?",
                        "Confirm Exit", "YesNo Icon?")

        if (result = "Yes") {
            ExitApp()
        }
    }

    ; Show notification (now uses TrayTip instead of ToolTip)
    static ShowNotification(title, message, duration := 3000) {
        TrayTip(title, message, "Icon")
    }
}
