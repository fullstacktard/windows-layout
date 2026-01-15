; Profile Manager - Handles profile CRUD operations
#Include JSON.ahk

class ProfileManager {
    static profilesDir := ""
    static profiles := Map()
    static profileErrors := Map()  ; Track profiles with loading errors

    ; Initialize profile manager
    static __New() {
        ; Set profiles directory to AppData
        this.profilesDir := A_AppData . "\WindowLayoutManager\Profiles"

        ; Create directory if it doesn't exist
        if (!DirExist(this.profilesDir)) {
            DirCreate(this.profilesDir)
        }

        ; Load existing profiles
        this.LoadAllProfiles()
    }

    ; Load all profiles from disk
    static LoadAllProfiles() {
        this.profiles := Map()
        this.profileErrors := Map()

        try {
            ; Get all .json files in profiles directory
            Loop Files, this.profilesDir . "\*.json" {
                fileName := A_LoopFileName
                try {
                    profileData := JSON.LoadFromFile(A_LoopFileFullPath)
                    if (profileData && profileData is Map && profileData.Has("profileName")) {
                        profileName := profileData["profileName"]
                        this.profiles[profileName] := profileData
                        ; Clear any previous error
                        if (this.profileErrors.Has(profileName)) {
                            this.profileErrors.Delete(profileName)
                        }
                    } else {
                        ; Invalid profile structure
                        this.profileErrors[fileName] := "Invalid profile format"
                    }
                } catch as e {
                    ; JSON parsing error
                    this.profileErrors[fileName] := "JSON parse error: " . e.Message
                    continue
                }
            }
        } catch {
            ; Directory doesn't exist or other error
        }
    }

    ; Save a profile to disk
    static SaveProfile(profileName, windows, hotkey := "") {
        try {
            ; Check if profile already exists to preserve hotkey and createdDate
            existingProfile := false
            if (this.profiles.Has(profileName)) {
                existingProfile := this.profiles[profileName]
            }

            ; Create profile object
            profile := Map()
            profile["profileName"] := profileName

            ; Preserve existing hotkey if not explicitly provided
            if (hotkey != "") {
                profile["hotkey"] := hotkey
            } else if (existingProfile && existingProfile.Has("hotkey")) {
                profile["hotkey"] := existingProfile["hotkey"]
            } else {
                profile["hotkey"] := ""
            }

            ; Preserve createdDate or set new one
            if (existingProfile && existingProfile.Has("createdDate")) {
                profile["createdDate"] := existingProfile["createdDate"]
            } else {
                profile["createdDate"] := A_Now
            }

            profile["modifiedDate"] := A_Now
            profile["windows"] := windows

            ; Generate filename from profile name
            fileName := this.SanitizeFileName(profileName) . ".json"
            filePath := this.profilesDir . "\" . fileName

            ; Save to disk
            result := JSON.SaveToFile(filePath, profile)

            if (result) {
                ; Update in-memory profiles
                this.profiles[profileName] := profile
                return true
            }

            return false
        } catch as e {
            MsgBox("Error saving profile: " . e.Message)
            return false
        }
    }

    ; Load a profile from disk
    static LoadProfile(profileName) {
        if (this.profiles.Has(profileName)) {
            return this.profiles[profileName]
        }

        ; Try to load from disk
        fileName := this.SanitizeFileName(profileName) . ".json"
        filePath := this.profilesDir . "\" . fileName

        if (FileExist(filePath)) {
            try {
                profile := JSON.LoadFromFile(filePath)
                this.profiles[profileName] := profile
                return profile
            } catch {
                return false
            }
        }

        return false
    }

    ; Delete a profile
    static DeleteProfile(profileName) {
        try {
            ; Remove from memory
            if (this.profiles.Has(profileName)) {
                this.profiles.Delete(profileName)
            }

            ; Delete file
            fileName := this.SanitizeFileName(profileName) . ".json"
            filePath := this.profilesDir . "\" . fileName

            if (FileExist(filePath)) {
                FileDelete(filePath)
            }

            return true
        } catch {
            return false
        }
    }

    ; Rename a profile
    static RenameProfile(oldName, newName) {
        try {
            ; Check if old profile exists
            if (!this.profiles.Has(oldName)) {
                return false
            }

            ; Check if new name already exists
            if (this.profiles.Has(newName)) {
                return false
            }

            ; Load old profile
            profile := this.profiles[oldName]

            ; Update profile name
            profile["profileName"] := newName
            profile["modifiedDate"] := A_Now

            ; Delete old file
            oldFileName := this.SanitizeFileName(oldName) . ".json"
            oldFilePath := this.profilesDir . "\" . oldFileName
            if (FileExist(oldFilePath)) {
                FileDelete(oldFilePath)
            }

            ; Save with new name
            newFileName := this.SanitizeFileName(newName) . ".json"
            newFilePath := this.profilesDir . "\" . newFileName
            JSON.SaveToFile(newFilePath, profile)

            ; Update in memory
            this.profiles.Delete(oldName)
            this.profiles[newName] := profile

            return true
        } catch {
            return false
        }
    }

    ; Duplicate a profile
    static DuplicateProfile(profileName, newName) {
        try {
            ; Check if source profile exists
            if (!this.profiles.Has(profileName)) {
                return false
            }

            ; Check if new name already exists
            if (this.profiles.Has(newName)) {
                return false
            }

            ; Load source profile
            sourceProfile := this.profiles[profileName]

            ; Create new profile with same windows but different name
            newProfile := Map()
            newProfile["profileName"] := newName
            newProfile["hotkey"] := "" ; Clear hotkey for duplicate
            newProfile["createdDate"] := A_Now
            newProfile["modifiedDate"] := A_Now
            newProfile["windows"] := sourceProfile["windows"]

            ; Save new profile
            fileName := this.SanitizeFileName(newName) . ".json"
            filePath := this.profilesDir . "\" . fileName
            JSON.SaveToFile(filePath, newProfile)

            ; Update in memory
            this.profiles[newName] := newProfile

            return true
        } catch {
            return false
        }
    }

    ; Get all profile names
    static GetProfileNames() {
        names := []
        for name in this.profiles {
            names.Push(name)
        }
        return names
    }

    ; Get profile count
    static GetProfileCount() {
        return this.profiles.Count
    }

    ; Check if profile exists
    static ProfileExists(profileName) {
        return this.profiles.Has(profileName)
    }

    ; Update profile hotkey
    static UpdateProfileHotkey(profileName, hotkey) {
        try {
            if (!this.profiles.Has(profileName)) {
                return false
            }

            profile := this.profiles[profileName]
            profile["hotkey"] := hotkey
            profile["modifiedDate"] := A_Now

            ; Save to disk
            fileName := this.SanitizeFileName(profileName) . ".json"
            filePath := this.profilesDir . "\" . fileName
            JSON.SaveToFile(filePath, profile)

            return true
        } catch {
            return false
        }
    }

    ; Update profile windows
    static UpdateProfileWindows(profileName, windows) {
        try {
            if (!this.profiles.Has(profileName)) {
                return false
            }

            profile := this.profiles[profileName]
            profile["windows"] := windows
            profile["modifiedDate"] := A_Now

            ; Save to disk
            fileName := this.SanitizeFileName(profileName) . ".json"
            filePath := this.profilesDir . "\" . fileName
            JSON.SaveToFile(filePath, profile)

            return true
        } catch {
            return false
        }
    }

    ; Sanitize filename (remove invalid characters)
    static SanitizeFileName(name) {
        ; Replace invalid characters with underscore
        invalidChars := ['<', '>', ':', '"', '/', '\', '|', '?', '*']
        sanitized := name

        for char in invalidChars {
            sanitized := StrReplace(sanitized, char, "_")
        }

        return sanitized
    }

    ; Export profile to file
    static ExportProfile(profileName, exportPath) {
        try {
            if (!this.profiles.Has(profileName)) {
                return false
            }

            profile := this.profiles[profileName]
            return JSON.SaveToFile(exportPath, profile)
        } catch {
            return false
        }
    }

    ; Import profile from file
    static ImportProfile(importPath) {
        try {
            profile := JSON.LoadFromFile(importPath)

            if (!profile || !profile.Has("profileName")) {
                return false
            }

            profileName := profile["profileName"]

            ; If profile with same name exists, add suffix
            if (this.profiles.Has(profileName)) {
                suffix := 1
                while (this.profiles.Has(profileName . " (" . suffix . ")")) {
                    suffix++
                }
                profileName := profileName . " (" . suffix . ")"
                profile["profileName"] := profileName
            }

            ; Save imported profile
            fileName := this.SanitizeFileName(profileName) . ".json"
            filePath := this.profilesDir . "\" . fileName
            JSON.SaveToFile(filePath, profile)

            ; Update in memory
            this.profiles[profileName] := profile

            return profileName
        } catch {
            return false
        }
    }

    ; Check if there are any profile errors
    static HasErrors() {
        return this.profileErrors.Count > 0
    }

    ; Get all profile errors
    static GetErrors() {
        return this.profileErrors
    }

    ; Get profile statistics
    static GetProfileStats(profileName) {
        if (!this.profiles.Has(profileName)) {
            return false
        }

        profile := this.profiles[profileName]
        windows := profile["windows"]

        stats := Map()
        stats["windowCount"] := windows.Length
        stats["createdDate"] := profile["createdDate"]
        stats["modifiedDate"] := profile["modifiedDate"]
        stats["hasHotkey"] := (profile["hotkey"] != "")

        ; Count desktops used
        desktops := Map()
        for windowInfo in windows {
            desktop := windowInfo["desktop"]
            desktops[desktop] := true
        }
        stats["desktopCount"] := desktops.Count

        ; Count unique processes
        processes := Map()
        for windowInfo in windows {
            processName := windowInfo["processName"]
            processes[processName] := true
        }
        stats["processCount"] := processes.Count

        return stats
    }
}
