; Hotkey Manager - Handles profile hotkeys with conflict detection
#Include ProfileManager.ahk
#Include WindowRestorer.ahk

class HotkeyManager {
    static registeredHotkeys := Map()
    static activeHotkeys := Map()
    static isRestoring := false  ; Flag to prevent multiple simultaneous restorations

    ; Initialize hotkey manager
    static Initialize() {
        this.registeredHotkeys := Map()
        this.activeHotkeys := Map()

        ; Load hotkeys from all profiles
        this.LoadAllHotkeys()
    }

    ; Load hotkeys from all profiles
    static LoadAllHotkeys() {
        ; Clear existing hotkeys
        this.UnregisterAllHotkeys()

        ; Get all profiles
        profiles := ProfileManager.GetProfileNames()

        for profileName in profiles {
            profile := ProfileManager.LoadProfile(profileName)

            if (profile && profile.Has("hotkey") && profile["hotkey"] != "") {
                hotkey := profile["hotkey"]

                ; Register the hotkey
                this.RegisterHotkey(profileName, hotkey)
            }
        }
    }

    ; Register a hotkey for a profile
    static RegisterHotkey(profileName, hotkeyStr) {
        try {
            ; Validate hotkey string
            if (!this.ValidateHotkey(hotkeyStr)) {
                return false
            }

            ; Check for conflicts
            if (this.activeHotkeys.Has(hotkeyStr)) {
                existingProfile := this.activeHotkeys[hotkeyStr]
                ; Hotkey already registered to another profile
                return false
            }

            ; Create hotkey handler
            handler := this.CreateHotkeyHandler(profileName)

            ; Register the hotkey
            Hotkey(hotkeyStr, handler, "On")

            ; Track the hotkey
            this.registeredHotkeys[profileName] := hotkeyStr
            this.activeHotkeys[hotkeyStr] := profileName

            return true
        } catch as e {
            ; Failed to register hotkey
            return false
        }
    }

    ; Unregister a hotkey for a profile
    static UnregisterHotkey(profileName) {
        try {
            if (!this.registeredHotkeys.Has(profileName)) {
                return true
            }

            hotkeyStr := this.registeredHotkeys[profileName]

            ; Disable the hotkey
            try {
                Hotkey(hotkeyStr, "Off")
            } catch {
                ; Hotkey might not exist
            }

            ; Remove from tracking
            this.registeredHotkeys.Delete(profileName)

            if (this.activeHotkeys.Has(hotkeyStr)) {
                this.activeHotkeys.Delete(hotkeyStr)
            }

            return true
        } catch {
            return false
        }
    }

    ; Unregister all hotkeys
    static UnregisterAllHotkeys() {
        for profileName in this.registeredHotkeys {
            hotkeyStr := this.registeredHotkeys[profileName]

            try {
                ; Turn off and delete the hotkey completely
                Hotkey(hotkeyStr, "Off")
                try {
                    Hotkey(hotkeyStr, , "Delete")  ; Completely remove the hotkey
                } catch {
                    ; Might fail if hotkey doesn't exist
                }
            } catch {
                ; Hotkey might not exist
            }
        }

        this.registeredHotkeys := Map()
        this.activeHotkeys := Map()
    }

    ; Create a hotkey handler for a specific profile
    static CreateHotkeyHandler(profileName) {
        return (*) => this.HandleHotkey(profileName)
    }

    ; Handle hotkey press
    static HandleHotkey(profileName) {
        ; Prevent multiple simultaneous restorations
        if (this.isRestoring) {
            return
        }

        try {
            this.isRestoring := true

            ; Load profile
            profile := ProfileManager.LoadProfile(profileName)

            if (!profile) {
                return
            }

            windows := profile["windows"]

            if (windows.Length = 0) {
                return
            }

            ; Restore layout
            result := WindowRestorer.RestoreLayout(windows)

        } catch as e {
            ; Error occurred
        } finally {
            ; Always reset the flag when done
            this.isRestoring := false
        }
    }

    ; Validate hotkey string
    static ValidateHotkey(hotkeyStr) {
        if (!hotkeyStr || hotkeyStr = "") {
            return false
        }

        ; Check for valid modifiers and key
        ; Valid modifiers: ^ (Ctrl), ! (Alt), + (Shift), # (Win)
        ; Allow combinations like ^!1, #w, etc.

        ; Basic validation - must contain at least one character
        if (StrLen(hotkeyStr) < 1) {
            return false
        }

        ; Try to parse the hotkey
        try {
            ; Test if hotkey is valid by trying to register it as disabled
            Hotkey(hotkeyStr, (*) => "", "Off")
            return true
        } catch {
            return false
        }
    }

    ; Check if hotkey is available (not in use)
    static IsHotkeyAvailable(hotkeyStr) {
        return !this.activeHotkeys.Has(hotkeyStr)
    }

    ; Get profile using a hotkey
    static GetProfileByHotkey(hotkeyStr) {
        if (this.activeHotkeys.Has(hotkeyStr)) {
            return this.activeHotkeys[hotkeyStr]
        }
        return ""
    }

    ; Update hotkey for a profile
    static UpdateHotkey(profileName, newHotkeyStr) {
        ; Unregister old hotkey
        this.UnregisterHotkey(profileName)

        ; Register new hotkey if not empty
        if (newHotkeyStr && newHotkeyStr != "") {
            return this.RegisterHotkey(profileName, newHotkeyStr)
        }

        return true
    }

    ; Get all active hotkeys
    static GetActiveHotkeys() {
        hotkeys := Map()

        for hotkeyStr, profileName in this.activeHotkeys {
            hotkeys[hotkeyStr] := profileName
        }

        return hotkeys
    }

    ; Check for hotkey conflicts
    static CheckConflict(hotkeyStr, excludeProfile := "") {
        if (this.activeHotkeys.Has(hotkeyStr)) {
            conflictProfile := this.activeHotkeys[hotkeyStr]

            ; If excluding a profile, check if conflict is with that profile
            if (excludeProfile != "" && conflictProfile = excludeProfile) {
                return ""
            }

            return conflictProfile
        }

        return ""
    }

    ; Format hotkey for display
    static FormatHotkeyDisplay(hotkeyStr) {
        if (!hotkeyStr || hotkeyStr = "") {
            return "None"
        }

        ; Replace symbols with readable names
        display := hotkeyStr
        display := StrReplace(display, "^", "Ctrl+")
        display := StrReplace(display, "!", "Alt+")
        display := StrReplace(display, "+", "Shift+")
        display := StrReplace(display, "#", "Win+")

        return display
    }

    ; Get hotkey suggestions
    static GetHotkeySuggestions() {
        suggestions := []

        ; Common hotkey patterns
        numbers := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
        letters := ["w", "e", "r", "d", "f", "l"]

        ; Ctrl+Alt+Number
        for num in numbers {
            hotkey := "^!" . num
            if (this.IsHotkeyAvailable(hotkey)) {
                suggestions.Push(hotkey)
            }
        }

        ; Win+Letter
        for letter in letters {
            hotkey := "#" . letter
            if (this.IsHotkeyAvailable(hotkey)) {
                suggestions.Push(hotkey)
            }
        }

        return suggestions
    }

    ; Test if a hotkey works
    static TestHotkey(hotkeyStr) {
        try {
            ; Try to create a temporary hotkey
            Hotkey(hotkeyStr, (*) => "", "Off")
            return { success: true, message: "Hotkey is valid" }
        } catch as e {
            return { success: false, message: e.Message }
        }
    }

    ; Reload all hotkeys (useful after profile changes)
    static Reload() {
        this.LoadAllHotkeys()
    }

    ; Get statistics
    static GetStats() {
        stats := Map()
        stats["totalRegistered"] := this.registeredHotkeys.Count
        stats["totalActive"] := this.activeHotkeys.Count

        return stats
    }
}
