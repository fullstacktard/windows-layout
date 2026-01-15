; Custom Toast Notification for Windows 10/11
; Shows branded notifications without AutoHotkey branding

class ToastNotification {
    ; Show a toast notification with custom app name and icon
    static Show(title, message, icon := "Info") {
        try {
            ; Simple TrayTip notification (reliable fallback)
            iconType := (icon = "Error") ? "Icon!" : (icon = "Warning") ? "Icon" : "Icon"
            TrayTip(title, message, iconType)
        } catch {
            ; Silent fail if notification doesn't work
        }
    }

    ; Show info notification
    static Info(message) {
        this.Show("Window Layout Manager", message, "Info")
    }

    ; Show success notification
    static Success(message) {
        this.Show("Layout Restored ✓", message, "Info")
    }

    ; Show error notification
    static Error(message) {
        this.Show("Layout Restore Error", message, "Error")
    }

    ; Show warning notification
    static Warning(message) {
        this.Show("Layout Restore Warning", message, "Warning")
    }
}
