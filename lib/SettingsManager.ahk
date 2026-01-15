; Settings Manager - Handles application settings
#Include JSON.ahk

class SettingsManager {
    static settingsFile := ""
    static settings := Map()

    ; Initialize settings manager
    static __New() {
        ; Set settings file path
        this.settingsFile := A_AppData . "\WindowLayoutManager\settings.json"

        ; Load settings
        this.LoadSettings()
    }

    ; Load settings from disk
    static LoadSettings() {
        try {
            if (FileExist(this.settingsFile)) {
                this.settings := JSON.LoadFromFile(this.settingsFile)
                if (!this.settings || !(this.settings is Map)) {
                    this.settings := Map()
                    this.SetDefaults()
                }
            } else {
                this.settings := Map()
                this.SetDefaults()
            }
        } catch {
            this.settings := Map()
            this.SetDefaults()
        }
    }

    ; Set default settings
    static SetDefaults() {
        if (!this.settings.Has("defaultProfile")) {
            this.settings["defaultProfile"] := ""
        }
        if (!this.settings.Has("autoRestoreOnStartup")) {
            this.settings["autoRestoreOnStartup"] := false
        }
        this.SaveSettings()
    }

    ; Save settings to disk
    static SaveSettings() {
        try {
            return JSON.SaveToFile(this.settingsFile, this.settings)
        } catch {
            return false
        }
    }

    ; Get a setting value
    static Get(key, defaultValue := "") {
        if (this.settings.Has(key)) {
            return this.settings[key]
        }
        return defaultValue
    }

    ; Set a setting value
    static Set(key, value) {
        this.settings[key] := value
        return this.SaveSettings()
    }

    ; Get default profile name
    static GetDefaultProfile() {
        return this.Get("defaultProfile", "")
    }

    ; Set default profile name
    static SetDefaultProfile(profileName) {
        return this.Set("defaultProfile", profileName)
    }

    ; Get auto-restore on startup setting
    static GetAutoRestoreOnStartup() {
        return this.Get("autoRestoreOnStartup", false)
    }

    ; Set auto-restore on startup
    static SetAutoRestoreOnStartup(enabled) {
        return this.Set("autoRestoreOnStartup", enabled)
    }
}
