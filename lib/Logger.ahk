; Simple logging utility
class Logger {
    static logFile := ""
    static enabled := true

    ; Initialize logger
    static __New() {
        ; Create logs directory
        logsDir := A_AppData . "\WindowLayoutManager\Logs"
        if (!DirExist(logsDir)) {
            DirCreate(logsDir)
        }

        ; Create log file with timestamp
        timestamp := FormatTime(, "yyyyMMdd_HHmmss")
        this.logFile := logsDir . "\restore_" . timestamp . ".log"
    }

    ; Log a message
    static Log(message, level := "INFO") {
        if (!this.enabled) {
            return
        }

        try {
            timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            logLine := Format("[{}] [{}] {}`n", timestamp, level, message)
            FileAppend(logLine, this.logFile)
        } catch {
            ; Silently fail if logging doesn't work
        }
    }

    ; Log debug message
    static Debug(message) {
        this.Log(message, "DEBUG")
    }

    ; Log info message
    static Info(message) {
        this.Log(message, "INFO")
    }

    ; Log warning message
    static Warn(message) {
        this.Log(message, "WARN")
    }

    ; Log error message
    static Error(message) {
        this.Log(message, "ERROR")
    }

    ; Get the current log file path
    static GetLogFilePath() {
        return this.logFile
    }
}
