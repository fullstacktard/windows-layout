; Main GUI for Window Layout Manager
#Include ProfileManager.ahk
#Include SettingsManager.ahk
#Include WindowScanner.ahk
#Include WindowRestorer.ahk

class MainGUI {
    static window := ""
    static profileList := ""
    static currentProfile := ""

    ; Create and show the main window
    static Show() {
        ; Create main window
        this.window := Gui("+Resize", "Window Layout Manager")
        this.window.SetFont("s10", "Segoe UI")

        ; Add title
        this.window.Add("Text", "x20 y20 w760", "Manage Your Window Layouts")
        this.window.SetFont("s9", "Segoe UI")

        ; Profile list
        this.window.Add("Text", "x20 y50", "Saved Profiles:")
        this.profileList := this.window.Add("ListBox", "x20 y70 w560 h300 vProfileList", [])
        this.profileList.OnEvent("DoubleClick", (*) => this.EditProfile())

        ; Error indicator (multi-line)
        this.window.Add("Text", "x20 y375 w560 h25 cRed vErrorText", "")

        ; Buttons
        btnNew := this.window.Add("Button", "x600 y70 w180 h35", "New Profile")
        btnNew.OnEvent("Click", (*) => this.NewProfile())

        btnEdit := this.window.Add("Button", "x600 y115 w180 h35", "Edit Profile")
        btnEdit.OnEvent("Click", (*) => this.EditProfile())

        btnDuplicate := this.window.Add("Button", "x600 y160 w180 h35", "Duplicate Profile")
        btnDuplicate.OnEvent("Click", (*) => this.DuplicateProfile())

        btnDelete := this.window.Add("Button", "x600 y205 w180 h35", "Delete Profile")
        btnDelete.OnEvent("Click", (*) => this.DeleteProfile())

        btnExport := this.window.Add("Button", "x600 y250 w180 h35", "Export JSON")
        btnExport.OnEvent("Click", (*) => this.ExportProfileJSON())

        btnRestore := this.window.Add("Button", "x600 y295 w180 h40", "Restore Layout")
        btnRestore.OnEvent("Click", (*) => this.RestoreProfile())

        btnCapture := this.window.Add("Button", "x600 y345 w180 h40", "Capture Current")
        btnCapture.OnEvent("Click", (*) => this.CaptureLayout())

        ; Statistics area
        this.window.Add("GroupBox", "x20 y380 w760 h100", "Profile Information")
        this.window.Add("Text", "x40 y410 w720 h60 vInfoText", "Select a profile to view details")

        ; Startup settings
        this.window.Add("GroupBox", "x20 y490 w760 h125", "Startup Settings")

        ; Auto-start checkbox
        this.autoStartCheck := this.window.Add("CheckBox", "x40 y515 w300", "Run at Windows startup")
        this.autoStartCheck.OnEvent("Click", (*) => this.ToggleAutoStart())

        ; Check current auto-start state
        if (this.IsAutoStartEnabled()) {
            this.autoStartCheck.Value := 1
        }

        ; Default profile dropdown
        this.window.Add("Text", "x40 y545", "Default Profile:")
        this.defaultProfileDDL := this.window.Add("DropDownList", "x150 y542 w280 vDefaultProfile", ["(None)"])
        this.defaultProfileDDL.OnEvent("Change", (*) => this.UpdateDefaultProfile())

        ; Auto-restore checkbox
        this.autoRestoreCheck := this.window.Add("CheckBox", "x40 y575 w400", "Auto-restore default profile on startup")
        this.autoRestoreCheck.OnEvent("Click", (*) => this.ToggleAutoRestore())

        ; Load default profile settings
        this.LoadDefaultProfileSettings()

        ; Minimize to tray button
        btnMinimize := this.window.Add("Button", "x600 y575 w180 h35", "Minimize to Tray")
        btnMinimize.OnEvent("Click", (*) => this.MinimizeToTray())

        ; Set window events
        this.window.OnEvent("Close", (*) => this.MinimizeToTray())
        this.window.OnEvent("Size", (*) => this.OnResize())

        ; Load profiles
        this.RefreshProfileList()

        ; Show window
        this.window.Show("w800 h650")
    }

    ; Refresh the profile list
    static RefreshProfileList() {
        ; Get all profile names
        profiles := ProfileManager.GetProfileNames()

        ; Clear and populate list
        this.profileList.Delete()
        for profileName in profiles {
            this.profileList.Add([profileName])
        }

        ; Refresh default profile dropdown if it exists
        try {
            this.LoadDefaultProfileSettings()
        } catch {
            ; Control doesn't exist yet or other error
        }

        ; Check for errors and display them
        if (ProfileManager.HasErrors()) {
            errors := ProfileManager.GetErrors()
            errorCount := errors.Count
            errorText := "⚠ " . errorCount . " profile(s) failed to load (corrupted JSON)"
            try {
                this.window["ErrorText"].Value := errorText
            } catch {
                ; Control doesn't exist yet
            }
        } else {
            try {
                this.window["ErrorText"].Value := ""
            } catch {
                ; Control doesn't exist yet
            }
        }

        ; Update info display if a profile was selected
        try {
            selected := this.profileList.Value
            if (selected > 0 && selected <= profiles.Length) {
                this.UpdateProfileInfo(profiles[selected])
            }
        } catch {
            ; No selection
        }
    }

    ; Update profile information display
    static UpdateProfileInfo(profileName) {
        stats := ProfileManager.GetProfileStats(profileName)

        if (stats) {
            profile := ProfileManager.LoadProfile(profileName)
            hotkey := profile["hotkey"]
            hotkeyText := (hotkey != "") ? hotkey : "None"

            infoText := Format("Profile: {}`n" .
                              "Windows: {} | Desktops: {} | Processes: {}`n" .
                              "Hotkey: {} | Modified: {}",
                              profileName,
                              stats["windowCount"],
                              stats["desktopCount"],
                              stats["processCount"],
                              hotkeyText,
                              this.FormatDateTime(stats["modifiedDate"]))

            try {
                this.window["InfoText"].Value := infoText
            } catch {
                ; Control doesn't exist yet
            }
        }
    }

    ; Format datetime for display
    static FormatDateTime(dateTime) {
        try {
            return FormatTime(dateTime, "yyyy-MM-dd HH:mm")
        } catch {
            return "Unknown"
        }
    }

    ; New profile button handler
    static NewProfile() {
        ; Prompt for profile name
        ib := InputBox("Enter a name for the new profile:", "New Profile", "w300 h150")

        if (ib.Result = "OK" && ib.Value != "") {
            profileName := ib.Value

            ; Check if profile already exists
            if (ProfileManager.ProfileExists(profileName)) {
                MsgBox("A profile with this name already exists!", "Error", "Icon!")
                return
            }

            ; Scan current windows
            MsgBox("Click OK to capture windows across all virtual desktops.`n`nNote: Your desktops will automatically switch during capture (this takes ~6 seconds).", "Capture Layout", "Icon!")

            windows := WindowScanner.ScanAllWindows()

            if (windows.Length = 0) {
                MsgBox("No windows found to capture!", "Warning", "Icon!")
                return
            }

            ; Save profile
            result := ProfileManager.SaveProfile(profileName, windows, "")

            if (result) {
                MsgBox("Profile '" . profileName . "' created with " . windows.Length . " windows!", "Success", "Icon")
                this.RefreshProfileList()
            } else {
                MsgBox("Failed to save profile!", "Error", "Icon!")
            }
        }
    }

    ; Edit profile button handler
    static EditProfile() {
        try {
            selected := this.profileList.Value
            profiles := ProfileManager.GetProfileNames()

            if (selected > 0 && selected <= profiles.Length) {
                profileName := profiles[selected]
                this.ShowProfileEditor(profileName)
            } else {
                MsgBox("Please select a profile to edit.", "No Selection", "Icon!")
            }
        } catch {
            MsgBox("Please select a profile to edit.", "No Selection", "Icon!")
        }
    }

    ; Show profile editor window
    static ShowProfileEditor(profileName) {
        profile := ProfileManager.LoadProfile(profileName)

        if (!profile) {
            MsgBox("Failed to load profile!", "Error", "Icon!")
            return
        }

        ; Create editor window
        editor := Gui("+Owner" . this.window.Hwnd, "Edit Profile - " . profileName)
        editor.SetFont("s9", "Segoe UI")

        ; Profile name
        editor.Add("Text", "x20 y20", "Profile Name:")
        nameEdit := editor.Add("Edit", "x120 y17 w300 vProfileName", profileName)

        ; Hotkey
        editor.Add("Text", "x20 y55", "Hotkey:")
        hotkeyEdit := editor.Add("Edit", "x120 y52 w200 vHotkey", profile["hotkey"])
        btnRecord := editor.Add("Button", "x330 y51 w90 h25", "Record Keys")
        btnRecord.OnEvent("Click", (*) => this.RecordHotkey(editor, hotkeyEdit))
        editor.Add("Text", "x120 y77 w300", "Example: ^!1 (Ctrl+Alt+1) or #w (Win+W)")

        ; Window list
        editor.Add("Text", "x20 y110", "Windows in this profile:")
        windowsList := editor.Add("ListBox", "x20 y130 w580 h250", [])

        ; Populate windows list
        windows := profile["windows"]
        for windowInfo in windows {
            displayText := WindowScanner.FormatWindowInfo(windowInfo)
            windowsList.Add([displayText])
        }

        ; Buttons
        btnSave := editor.Add("Button", "x20 y400 w120 h35", "Save Changes")
        btnRecapture := editor.Add("Button", "x160 y400 w150 h35", "Recapture Layout")
        btnCancel := editor.Add("Button", "x480 y400 w120 h35", "Cancel")

        ; Button events
        btnSave.OnEvent("Click", (*) => this.SaveProfileEdits(editor, profileName))
        btnRecapture.OnEvent("Click", (*) => this.RecaptureProfile(editor, profileName))
        btnCancel.OnEvent("Click", (*) => editor.Destroy())

        editor.Show("w620 h450")
    }

    ; Save profile edits
    static SaveProfileEdits(editor, oldProfileName) {
        try {
            newProfileName := editor["ProfileName"].Value
            hotkey := editor["Hotkey"].Value

            ; Check if name changed and new name exists
            if (newProfileName != oldProfileName && ProfileManager.ProfileExists(newProfileName)) {
                MsgBox("A profile with this name already exists!", "Error", "Icon!")
                return
            }

            ; Rename if name changed
            if (newProfileName != oldProfileName) {
                ProfileManager.RenameProfile(oldProfileName, newProfileName)
            }

            ; Update hotkey
            ProfileManager.UpdateProfileHotkey(newProfileName, hotkey)

            ; Reload hotkeys to register the new one
            HotkeyManager.Reload()

            MsgBox("Profile updated successfully!", "Success", "Icon")
            editor.Destroy()
            this.RefreshProfileList()
        } catch as e {
            MsgBox("Error saving profile: " . e.Message, "Error", "Icon!")
        }
    }

    ; Recapture profile layout
    static RecaptureProfile(editor, profileName) {
        result := MsgBox("This will replace the current layout with the current window arrangement. Continue?",
                        "Confirm Recapture", "YesNo Icon?")

        if (result = "Yes") {
            windows := WindowScanner.ScanAllWindows()

            if (windows.Length = 0) {
                MsgBox("No windows found to capture!", "Warning", "Icon!")
                return
            }

            ; Get current hotkey
            profile := ProfileManager.LoadProfile(profileName)
            hotkey := profile["hotkey"]

            ; Save updated profile
            result := ProfileManager.SaveProfile(profileName, windows, hotkey)

            if (result) {
                MsgBox("Layout recaptured with " . windows.Length . " windows!", "Success", "Icon")
                editor.Destroy()
                this.RefreshProfileList()
            }
        }
    }

    ; Duplicate profile button handler
    static DuplicateProfile() {
        try {
            selected := this.profileList.Value
            profiles := ProfileManager.GetProfileNames()

            if (selected > 0 && selected <= profiles.Length) {
                profileName := profiles[selected]

                ; Prompt for new name
                ib := InputBox("Enter a name for the duplicate profile:", "Duplicate Profile",
                              "w300 h150", profileName . " Copy")

                if (ib.Result = "OK" && ib.Value != "") {
                    newName := ib.Value

                    result := ProfileManager.DuplicateProfile(profileName, newName)

                    if (result) {
                        MsgBox("Profile duplicated successfully!", "Success", "Icon")
                        this.RefreshProfileList()
                    } else {
                        MsgBox("Failed to duplicate profile!", "Error", "Icon!")
                    }
                }
            } else {
                MsgBox("Please select a profile to duplicate.", "No Selection", "Icon!")
            }
        } catch {
            MsgBox("Please select a profile to duplicate.", "No Selection", "Icon!")
        }
    }

    ; Delete profile button handler
    static DeleteProfile() {
        try {
            selected := this.profileList.Value
            profiles := ProfileManager.GetProfileNames()

            if (selected > 0 && selected <= profiles.Length) {
                profileName := profiles[selected]

                result := MsgBox("Are you sure you want to delete profile '" . profileName . "'?",
                                "Confirm Delete", "YesNo Icon?")

                if (result = "Yes") {
                    ; First unregister any hotkey associated with this profile
                    profile := ProfileManager.LoadProfile(profileName)
                    if (profile && profile.Has("hotkey") && profile["hotkey"] != "") {
                        try {
                            Hotkey(profile["hotkey"], "Off")
                        } catch {
                            ; Hotkey wasn't registered or error
                        }
                    }

                    ; Now delete the profile
                    if (ProfileManager.DeleteProfile(profileName)) {
                        ; Reload hotkeys to refresh the hotkey manager
                        HotkeyManager.Reload()

                        MsgBox("Profile deleted successfully!", "Success", "Icon")
                        this.RefreshProfileList()
                    } else {
                        MsgBox("Failed to delete profile!", "Error", "Icon!")
                    }
                }
            } else {
                MsgBox("Please select a profile to delete.", "No Selection", "Icon!")
            }
        } catch {
            MsgBox("Please select a profile to delete.", "No Selection", "Icon!")
        }
    }

    ; Export profile JSON button handler
    static ExportProfileJSON() {
        try {
            selected := this.profileList.Value
            profiles := ProfileManager.GetProfileNames()

            if (selected > 0 && selected <= profiles.Length) {
                profileName := profiles[selected]

                ; Load the profile
                profile := ProfileManager.LoadProfile(profileName)

                if (!profile) {
                    MsgBox("Failed to load profile!", "Error", "Icon!")
                    return
                }

                ; Convert to formatted JSON string
                jsonStr := JSON.Stringify(profile, "  ")

                ; Copy to clipboard
                A_Clipboard := jsonStr

                ; Show success message with JSON preview
                previewLength := 500
                preview := (StrLen(jsonStr) > previewLength) ? SubStr(jsonStr, 1, previewLength) . "`n..." : jsonStr

                MsgBox("JSON copied to clipboard!`n`nProfile: " . profileName . "`nWindows: " . profile["windows"].Length . "`n`nPreview:`n" . preview,
                      "Export Complete", "Icon")

            } else {
                MsgBox("Please select a profile to export.", "No Selection", "Icon!")
            }
        } catch as e {
            MsgBox("Failed to export profile: " . e.Message, "Error", "Icon!")
        }
    }

    ; Restore profile button handler
    static RestoreProfile() {
        try {
            selected := this.profileList.Value
            profiles := ProfileManager.GetProfileNames()

            if (selected > 0 && selected <= profiles.Length) {
                profileName := profiles[selected]
                this.RestoreLayoutByName(profileName)
            } else {
                MsgBox("Please select a profile to restore.", "No Selection", "Icon!")
            }
        } catch {
            MsgBox("Please select a profile to restore.", "No Selection", "Icon!")
        }
    }

    ; Restore layout by profile name
    static RestoreLayoutByName(profileName) {
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

        ; Clear any previous error messages
        try {
            this.window["ErrorText"].Value := ""
        }

        ; Restore layout (no progress window)
        result := WindowRestorer.RestoreLayout(windows)

        ; Show error in GUI if any failures occurred
        if (result.failed > 0) {
            errorMsg := Format("⚠ Restore completed with {} failures (check logs for details)", result.failed)
            try {
                this.window["ErrorText"].Value := errorMsg
            }
        }
    }

    ; Capture layout button handler
    static CaptureLayout() {
        try {
            selected := this.profileList.Value
            profiles := ProfileManager.GetProfileNames()

            if (selected > 0 && selected <= profiles.Length) {
                profileName := profiles[selected]
                this.RecaptureProfileDirect(profileName)
            } else {
                ; No profile selected, create new
                this.NewProfile()
            }
        } catch {
            this.NewProfile()
        }
    }

    ; Recapture profile directly
    static RecaptureProfileDirect(profileName) {
        result := MsgBox("Update profile '" . profileName . "' with current window layout?",
                        "Confirm Capture", "YesNo Icon?")

        if (result = "Yes") {
            windows := WindowScanner.ScanAllWindows()

            if (windows.Length = 0) {
                MsgBox("No windows found to capture!", "Warning", "Icon!")
                return
            }

            profile := ProfileManager.LoadProfile(profileName)
            hotkey := profile["hotkey"]

            result := ProfileManager.SaveProfile(profileName, windows, hotkey)

            if (result) {
                MsgBox("Profile updated with " . windows.Length . " windows!", "Success", "Icon")
                this.RefreshProfileList()
            }
        }
    }

    ; Minimize to tray
    static MinimizeToTray() {
        this.window.Hide()
    }

    ; Restore from tray
    static RestoreFromTray() {
        this.window.Show()
        WinActivate(this.window)
    }

    ; Handle window resize
    static OnResize() {
        ; Could implement responsive resizing here
    }

    ; Toggle auto-start
    static ToggleAutoStart() {
        if (this.autoStartCheck.Value) {
            this.EnableAutoStart()
        } else {
            this.DisableAutoStart()
        }
    }

    ; Check if auto-start is enabled
    static IsAutoStartEnabled() {
        try {
            startupFolder := A_Startup
            linkPath := startupFolder . "\WindowLayoutManager.lnk"
            return FileExist(linkPath)
        } catch {
            return false
        }
    }

    ; Enable auto-start
    static EnableAutoStart() {
        try {
            startupFolder := A_Startup
            linkPath := startupFolder . "\WindowLayoutManager.lnk"
            targetPath := A_ScriptFullPath

            ; Create shortcut using COM
            shell := ComObject("WScript.Shell")
            shortcut := shell.CreateShortcut(linkPath)
            shortcut.TargetPath := targetPath
            shortcut.WorkingDirectory := A_ScriptDir
            shortcut.Description := "Window Layout Manager"
            shortcut.Save()

            ToolTip("Auto-start enabled")
            SetTimer(() => ToolTip(), -2000)
        } catch as e {
            MsgBox("Failed to enable auto-start: " . e.Message, "Error", "Icon!")
            this.autoStartCheck.Value := 0
        }
    }

    ; Disable auto-start
    static DisableAutoStart() {
        try {
            startupFolder := A_Startup
            linkPath := startupFolder . "\WindowLayoutManager.lnk"

            if (FileExist(linkPath)) {
                FileDelete(linkPath)
            }

            ToolTip("Auto-start disabled")
            SetTimer(() => ToolTip(), -2000)
        } catch as e {
            MsgBox("Failed to disable auto-start: " . e.Message, "Error", "Icon!")
            this.autoStartCheck.Value := 1
        }
    }

    ; Record hotkey by pressing keys
    static RecordHotkey(editor, hotkeyEdit) {
        ; Create hotkey recorder dialog
        recorder := Gui("+Owner" . editor.Hwnd " +ToolWindow", "Record Hotkey")
        recorder.SetFont("s10", "Segoe UI")

        recorder.Add("Text", "x20 y20 w260 Center", "Press your desired key combination...")
        statusText := recorder.Add("Text", "x20 y50 w260 h30 Center vStatus", "Waiting...")

        btnCancel := recorder.Add("Button", "x90 y100 w120 h30", "Cancel")
        btnCancel.OnEvent("Click", (*) => recorder.Destroy())

        recorder.Show("w300 h150")

        ; Use InputHook to capture key combination
        ih := InputHook("L1 T5")  ; 1 key, 5 second timeout
        ih.KeyOpt("{All}", "E")  ; Enable all keys as ending keys
        ih.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E")  ; Exclude modifiers from ending

        ; Capture modifiers and key
        ih.OnEnd := (hook) => this.ProcessRecordedHotkey(hook, hotkeyEdit, recorder, statusText)
        ih.Start()
    }

    ; Process the recorded hotkey
    static ProcessRecordedHotkey(hook, hotkeyEdit, recorder, statusText) {
        key := hook.EndKey

        ; Build hotkey string from modifiers
        hotkeyStr := ""

        ; Check modifiers
        if (GetKeyState("Ctrl", "P"))
            hotkeyStr .= "^"
        if (GetKeyState("Alt", "P"))
            hotkeyStr .= "!"
        if (GetKeyState("Shift", "P"))
            hotkeyStr .= "+"
        if (GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))
            hotkeyStr .= "#"

        ; Add the actual key
        if (key != "") {
            ; Convert special keys
            key := StrReplace(key, "Control", "")
            key := StrReplace(key, "Alt", "")
            key := StrReplace(key, "Shift", "")
            key := StrReplace(key, "LWin", "")
            key := StrReplace(key, "RWin", "")

            if (key != "") {
                hotkeyStr .= key
            }
        }

        ; Update the hotkey field
        if (hotkeyStr != "" && hotkeyStr != "^" && hotkeyStr != "!" && hotkeyStr != "+" && hotkeyStr != "#") {
            hotkeyEdit.Value := hotkeyStr
            statusText.Value := "Recorded: " . hotkeyStr
            SetTimer(() => recorder.Destroy(), -1000)
        } else {
            statusText.Value := "Invalid combination. Try again..."
            SetTimer(() => this.RecordHotkey(recorder.Hwnd, hotkeyEdit), -1500)
            SetTimer(() => recorder.Destroy(), -1400)
        }
    }

    ; Load default profile settings
    static LoadDefaultProfileSettings() {
        try {
            ; Populate dropdown with profiles
            profiles := ProfileManager.GetProfileNames()
            items := ["(None)"]

            for profileName in profiles {
                items.Push(profileName)
            }

            this.defaultProfileDDL.Delete()
            this.defaultProfileDDL.Add(items)

            ; Select current default profile
            defaultProfile := SettingsManager.GetDefaultProfile()
            if (defaultProfile && defaultProfile != "") {
                ; Find index of default profile
                for index, item in items {
                    if (item = defaultProfile) {
                        this.defaultProfileDDL.Choose(index)
                        break
                    }
                }
            } else {
                this.defaultProfileDDL.Choose(1)  ; Select "(None)"
            }

            ; Set auto-restore checkbox
            autoRestore := SettingsManager.GetAutoRestoreOnStartup()
            this.autoRestoreCheck.Value := autoRestore ? 1 : 0
        } catch as e {
            ; Silently fail if settings can't be loaded
        }
    }

    ; Update default profile
    static UpdateDefaultProfile() {
        try {
            selectedText := this.defaultProfileDDL.Text

            if (selectedText = "(None)") {
                SettingsManager.SetDefaultProfile("")
                ToolTip("Default profile cleared")
            } else {
                SettingsManager.SetDefaultProfile(selectedText)
                ToolTip("Default profile set to: " . selectedText)
            }

            SetTimer(() => ToolTip(), -2000)
        } catch as e {
            MsgBox("Failed to update default profile: " . e.Message, "Error", "Icon!")
        }
    }

    ; Toggle auto-restore
    static ToggleAutoRestore() {
        try {
            enabled := this.autoRestoreCheck.Value
            SettingsManager.SetAutoRestoreOnStartup(enabled)

            if (enabled) {
                ToolTip("Auto-restore enabled")
            } else {
                ToolTip("Auto-restore disabled")
            }

            SetTimer(() => ToolTip(), -2000)
        } catch as e {
            MsgBox("Failed to update auto-restore setting: " . e.Message, "Error", "Icon!")
        }
    }

    ; Destroy window
    static Destroy() {
        if (this.window) {
            this.window.Destroy()
        }
    }
}
