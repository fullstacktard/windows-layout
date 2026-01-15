; Progress Indicator - Shows progress in taskbar during restore operations

class ProgressIndicator {
    static window := ""
    static progressBar := ""
    static statusText := ""
    static isShowing := false

    ; Show the progress indicator
    static Show(totalWindows) {
        if (this.isShowing) {
            return
        }

        ; Create a small window that appears in the taskbar
        this.window := Gui("+AlwaysOnTop -SysMenu", "Restoring Layout...")
        this.window.SetFont("s9", "Segoe UI")

        ; Add status text
        this.statusText := this.window.Add("Text", "x20 y15 w360 Center", "Preparing to restore " . totalWindows . " windows...")

        ; Add progress bar
        this.progressBar := this.window.Add("Progress", "x20 y45 w360 h25 Range0-" . totalWindows, 0)

        ; Add percentage text
        this.percentText := this.window.Add("Text", "x20 y75 w360 Center", "0%")

        ; Show the window (small and centered)
        this.window.Show("w400 h110 Center")
        this.isShowing := true

        ; Force window to show in taskbar
        WinSetStyle("+0x40000", this.window.Hwnd)  ; WS_SIZEBOX to ensure taskbar button
    }

    ; Update progress
    static Update(current, total, windowInfo := "") {
        if (!this.isShowing) {
            return
        }

        try {
            ; Update progress bar
            this.progressBar.Value := current

            ; Calculate percentage
            percentage := Round((current / total) * 100)

            ; Update status text
            if (windowInfo) {
                windowTitle := windowInfo["windowTitle"]
                ; Truncate long titles
                if (StrLen(windowTitle) > 40) {
                    windowTitle := SubStr(windowTitle, 1, 37) . "..."
                }
                this.statusText.Value := Format("Restoring: {}", windowTitle)
            } else {
                this.statusText.Value := Format("Processing window {} of {}", current, total)
            }

            ; Update percentage
            this.percentText.Value := percentage . "%"
        } catch {
            ; Silently continue if update fails
        }
    }

    ; Show completion message briefly
    static ShowComplete(restored, failed, minimized) {
        if (!this.isShowing) {
            return
        }

        try {
            this.statusText.Value := Format("Complete! Restored: {} | Failed: {} | Minimized: {}", restored, failed, minimized)
            this.percentText.Value := "100%"
            this.progressBar.Value := this.progressBar.Max

            ; Auto-close after 2 seconds
            SetTimer(() => ProgressIndicator.Hide(), -2000)
        } catch {
            this.Hide()
        }
    }

    ; Hide the progress indicator
    static Hide() {
        if (this.isShowing && this.window) {
            try {
                this.window.Destroy()
            } catch {
                ; Window already destroyed
            }
            this.window := ""
            this.isShowing := false
        }
    }
}
