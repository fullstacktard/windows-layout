; Loading GUI - Shows a centered, locked loading dialog during restoration
#Include Logger.ahk

class LoadingGUI {
    static gui := 0
    static progressText := 0
    static startTime := 0
    static timeoutTimer := 0
    static maxTimeout := 30000  ; 30 seconds
    static isActive := false

    ; Show the loading GUI centered on screen
    static Show(message := "Restoring Layout...") {
        try {
            if (this.isActive) {
                return
            }

            this.isActive := true
            this.startTime := A_TickCount

            ; Create GUI (ToolWindow prevents taskbar icon)
            this.gui := Gui("+AlwaysOnTop +Disabled -Caption +Border +ToolWindow", "Window Layout Manager")
            this.gui.BackColor := "0x2D2D30"
            this.gui.MarginX := 30
            this.gui.MarginY := 30

            ; Add loading animation (using text-based spinner)
            this.gui.SetFont("s24 cWhite", "Segoe UI")
            this.gui.Add("Text", "Center w300", "⏳")

            ; Add message
            this.gui.SetFont("s12 cWhite", "Segoe UI")
            this.progressText := this.gui.Add("Text", "Center w300 vProgressText", message)

            ; No timer info needed - silent progress

            ; Show GUI
            this.gui.Show("NoActivate")

            ; Center on screen
            this.CenterOnScreen()

            ; Start timeout timer
            this.timeoutTimer := SetTimer(() => this.CheckTimeout(), 1000)

            Logger.Info("Loading GUI shown")
        } catch as e {
            Logger.Error(Format("Error showing loading GUI: {}", e.Message))
        }
    }

    ; Update the progress message
    static UpdateProgress(message) {
        try {
            if (!this.isActive || !this.progressText) {
                return
            }

            this.progressText.Value := message
            Logger.Debug(Format("Loading GUI: {}", message))
        } catch as e {
            Logger.Error(Format("Error updating loading GUI: {}", e.Message))
        }
    }

    ; Hide the loading GUI
    static Hide() {
        try {
            if (!this.isActive) {
                return
            }

            ; Stop timeout timer
            if (this.timeoutTimer) {
                SetTimer(this.timeoutTimer, 0)
                this.timeoutTimer := 0
            }

            ; Destroy GUI
            if (this.gui) {
                this.gui.Destroy()
                this.gui := 0
            }

            this.isActive := false
            this.progressText := 0

            Logger.Info("Loading GUI hidden")
        } catch as e {
            Logger.Error(Format("Error hiding loading GUI: {}", e.Message))
        }
    }

    ; Check if timeout has been reached
    static CheckTimeout() {
        try {
            ; Stop if no longer active
            if (!this.isActive) {
                if (this.timeoutTimer) {
                    SetTimer(this.timeoutTimer, 0)
                    this.timeoutTimer := 0
                }
                return
            }

            elapsed := A_TickCount - this.startTime

            if (elapsed >= this.maxTimeout) {
                Logger.Warn(Format("Loading timeout reached after {}ms", elapsed))
                this.Hide()
                MsgBox("Layout restoration timed out.`n`nSome windows may not have been restored.", "Timeout", "Icon!")
            }
        } catch as e {
            Logger.Error(Format("Error in timeout check: {}", e.Message))
        }
    }

    ; Center GUI on screen
    static CenterOnScreen() {
        try {
            if (!this.gui) {
                return
            }

            ; Get GUI position and size
            this.gui.GetPos(, , &guiWidth, &guiHeight)

            ; Get screen dimensions
            screenWidth := A_ScreenWidth
            screenHeight := A_ScreenHeight

            ; Calculate center position
            x := (screenWidth - guiWidth) // 2
            y := (screenHeight - guiHeight) // 2

            ; Move GUI to center
            this.gui.Move(x, y)
        } catch as e {
            Logger.Error(Format("Error centering GUI: {}", e.Message))
        }
    }

    ; Force hide (for cleanup)
    static ForceHide() {
        try {
            this.isActive := false

            if (this.timeoutTimer) {
                SetTimer(this.timeoutTimer, 0)
                this.timeoutTimer := 0
            }

            if (this.gui) {
                try {
                    this.gui.Destroy()
                } catch {
                    ; Ignore errors during force hide
                }
                this.gui := 0
            }
        } catch {
            ; Ignore all errors during force hide
        }
    }
}
