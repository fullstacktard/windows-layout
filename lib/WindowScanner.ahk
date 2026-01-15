; Window Scanner - Captures window layouts across virtual desktops
#Include VirtualDesktop.ahk

class WindowScanner {
    ; Scan all windows and return array of window information
    ; Switches between virtual desktops to capture windows from each desktop
    static ScanAllWindows() {
        windows := []
        capturedHwnds := Map()  ; Track which windows we've already captured

        ; Save current desktop to restore later
        originalDesktop := VirtualDesktop.GetCurrentDesktopNumber()
        Logger.Info(Format("Starting capture from desktop {}", originalDesktop))

        ; Get total number of desktops
        desktopCount := VirtualDesktop.GetDesktopCount()
        Logger.Info(Format("Found {} virtual desktops", desktopCount))

        ; Loop through each desktop and capture windows
        Loop desktopCount {
            desktopNum := A_Index

            Logger.Info(Format("Scanning desktop {}/{}", desktopNum, desktopCount))

            ; Switch to this desktop
            VirtualDesktop.SwitchToDesktop(desktopNum)
            Sleep(200)  ; Give time for desktop switch to complete

            ; Get windows on current desktop
            allWindows := WinGetList()
            Logger.Debug(Format("Found {} total windows on desktop {}", allWindows.Length, desktopNum))

            for hwnd in allWindows {
                try {
                    ; Skip if already captured
                    if (capturedHwnds.Has(hwnd)) {
                        continue
                    }

                    ; Get basic info
                    processName := WinGetProcessName("ahk_id " . hwnd)
                    title := WinGetTitle("ahk_id " . hwnd)

                    ; Skip if no process
                    if (!processName) {
                        continue
                    }

                    ; Skip this app
                    if (InStr(processName, "WindowLayoutManager") || InStr(processName, "AutoHotkey64")) {
                        continue
                    }

                    ; Skip system processes
                    excludeProcesses := ["ShellExperienceHost.exe", "SearchUI.exe",
                                        "StartMenuExperienceHost.exe", "TextInputHost.exe",
                                        "LockApp.exe", "NVIDIA Overlay.exe"]
                    skipWindow := false
                    for exclude in excludeProcesses {
                        if (InStr(processName, exclude)) {
                            skipWindow := true
                            break
                        }
                    }
                    if (skipWindow) {
                        continue
                    }

                    ; Skip desktop window (Program Manager)
                    if (title = "Program Manager") {
                        continue
                    }

                    ; Skip IME windows by title
                    if (InStr(title, "Default IME") || InStr(title, "IME") && StrLen(title) < 15) {
                        continue
                    }

                    ; Get window size and position
                    WinGetPos(&x, &y, &width, &height, "ahk_id " . hwnd)

                    ; Skip windows with 0 width or height (hidden processes)
                    if (width <= 0 || height <= 0) {
                        continue
                    }

                    ; Skip taskbar windows (explorer.exe, small height, at bottom of screen)
                    if (processName = "explorer.exe" && height < 100 && y > 1300) {
                        continue
                    }

                    ; Must be visible
                    style := WinGetStyle("ahk_id " . hwnd)
                    if (!(style & 0x10000000)) {  ; WS_VISIBLE
                        continue
                    }

                    ; Get window info and set desktop number
                    windowInfo := this.GetWindowInfo(hwnd)
                    if (windowInfo) {
                        windowInfo["desktop"] := desktopNum
                        windows.Push(windowInfo)
                        capturedHwnds[hwnd] := true
                        Logger.Debug(Format("Captured: {} - {}", processName, title))
                    }
                } catch {
                    continue
                }
            }

            Logger.Info(Format("Captured {} windows from desktop {}", windows.Length, desktopNum))
        }

        ; Return to original desktop
        Logger.Info(Format("Returning to desktop {}", originalDesktop))
        VirtualDesktop.SwitchToDesktop(originalDesktop)
        Sleep(200)

        Logger.Info(Format("Capture complete: {} total windows across {} desktops", windows.Length, desktopCount))
        return windows
    }

    ; Check if window should be included in layout
    static ShouldIncludeWindow(hwnd) {
        try {
            ; Get window title and process
            title := WinGetTitle("ahk_id " . hwnd)
            processName := WinGetProcessName("ahk_id " . hwnd)

            ; Skip if no process
            if (!processName) {
                return false
            }

            ; Skip this application itself!
            if (InStr(processName, "WindowLayoutManager")) {
                return false
            }

            ; Skip invisible windows
            if (!WinExist("ahk_id " . hwnd)) {
                return false
            }

            ; Skip minimized to system tray or invisible windows
            style := WinGetStyle("ahk_id " . hwnd)
            if (!(style & 0x10000000)) { ; WS_VISIBLE
                return false
            }

            ; Skip child windows (only get top-level windows)
            if (DllCall("GetParent", "Ptr", hwnd, "Ptr")) {
                return false
            }

            ; Skip tool windows completely (they're usually child processes)
            exStyle := WinGetExStyle("ahk_id " . hwnd)
            if (exStyle & 0x80) { ; WS_EX_TOOLWINDOW
                return false
            }

            ; Skip certain process names
            excludeProcesses := ["ShellExperienceHost.exe",
                                 "SearchUI.exe", "StartMenuExperienceHost.exe",
                                 "TextInputHost.exe", "LockApp.exe",
                                 "ApplicationFrameHost.exe"]

            for exclude in excludeProcesses {
                if (InStr(processName, exclude)) {
                    return false
                }
            }

            ; Skip IME windows by title
            if (InStr(title, "Default IME") || InStr(title, "IME") && StrLen(title) < 15) {
                return false
            }

            ; Skip windows with certain class names
            className := WinGetClass("ahk_id " . hwnd)
            excludeClasses := ["Shell_TrayWnd", "Shell_SecondaryTrayWnd", "DummyDWMListenerWindow",
                              "ForegroundStaging", "ApplicationManager_DesktopShellWindow",
                              "Windows.UI.Core.CoreWindow", "IME", "MSCTFIME UI"]

            for exclude in excludeClasses {
                if (InStr(className, exclude)) {
                    return false
                }
            }

            return true
        } catch {
            return false
        }
    }

    ; Get detailed information about a window
    static GetWindowInfo(hwnd) {
        try {
            ; Get basic window information
            title := WinGetTitle("ahk_id " . hwnd)
            processName := WinGetProcessName("ahk_id " . hwnd)
            processPID := WinGetPID("ahk_id " . hwnd)

            ; Get window position and size
            WinGetPos(&x, &y, &width, &height, "ahk_id " . hwnd)

            ; Check if maximized or minimized
            minMax := WinGetMinMax("ahk_id " . hwnd)
            maximized := (minMax = 1)
            minimized := (minMax = -1)

            ; Get executable path
            execPath := ""
            try {
                execPath := ProcessGetPath(processPID)
            } catch {
                execPath := processName
            }

            ; For Explorer windows, capture the actual folder path
            explorerPath := ""
            if (processName = "explorer.exe") {
                try {
                    explorerPath := this.GetExplorerPath(hwnd)
                } catch {
                    explorerPath := ""
                }
            }

            ; Create window info map
            windowInfo := Map()
            windowInfo["hwnd"] := hwnd
            windowInfo["processName"] := processName
            windowInfo["windowTitle"] := title
            windowInfo["x"] := x
            windowInfo["y"] := y
            windowInfo["width"] := width
            windowInfo["height"] := height
            windowInfo["desktop"] := 1  ; Will be set by caller
            windowInfo["maximized"] := maximized
            windowInfo["minimized"] := minimized
            windowInfo["executablePath"] := execPath
            windowInfo["explorerPath"] := explorerPath  ; Store folder path for Explorer windows

            return windowInfo
        } catch as e {
            return false
        }
    }

    ; Get user-friendly display name for window
    static GetWindowDisplayName(windowInfo) {
        title := windowInfo["windowTitle"]
        processName := windowInfo["processName"]

        ; Shorten long titles
        if (StrLen(title) > 50) {
            title := SubStr(title, 1, 47) . "..."
        }

        return processName . " - " . title
    }

    ; Format window info for display
    static FormatWindowInfo(windowInfo) {
        processName := windowInfo["processName"]
        title := windowInfo["windowTitle"]
        desktop := windowInfo["desktop"]
        x := windowInfo["x"]
        y := windowInfo["y"]
        width := windowInfo["width"]
        height := windowInfo["height"]
        maximized := windowInfo["maximized"] ? " (Maximized)" : ""

        return Format("[Desktop {}] {} - {} ({}x{} at {},{}){}",
            desktop, processName, title, width, height, x, y, maximized)
    }

    ; Count windows per virtual desktop
    static CountWindowsPerDesktop(windows) {
        desktopCounts := Map()

        for windowInfo in windows {
            desktop := windowInfo["desktop"]
            if (!desktopCounts.Has(desktop)) {
                desktopCounts[desktop] := 0
            }
            desktopCounts[desktop] := desktopCounts[desktop] + 1
        }

        return desktopCounts
    }

    ; Group windows by process name
    static GroupWindowsByProcess(windows) {
        processGroups := Map()

        for windowInfo in windows {
            processName := windowInfo["processName"]
            if (!processGroups.Has(processName)) {
                processGroups[processName] := []
            }
            processGroups[processName].Push(windowInfo)
        }

        return processGroups
    }

    ; Get the folder path from an Explorer window
    static GetExplorerPath(hwnd) {
        try {
            shell := ComObject("Shell.Application")
            windows := shell.Windows()

            for window in windows {
                try {
                    ; Check if this is the Explorer window we're looking for
                    if (window.HWND = hwnd) {
                        ; Get the location URL and convert from file:/// format
                        path := window.LocationURL
                        if (InStr(path, "file:///")) {
                            ; Convert file:/// URL to Windows path
                            path := StrReplace(path, "file:///", "")
                            path := StrReplace(path, "/", "\")
                            ; Decode URL encoding (e.g., %20 -> space)
                            path := this.UrlDecode(path)
                            return path
                        }
                        ; If it's a special folder, return the name
                        return window.LocationName
                    }
                } catch {
                    continue
                }
            }
        } catch {
            ; Failed to get Explorer path
        }
        return ""
    }

    ; Simple URL decode for Explorer paths
    static UrlDecode(str) {
        str := StrReplace(str, "%20", " ")
        str := StrReplace(str, "%21", "!")
        str := StrReplace(str, "%23", "#")
        str := StrReplace(str, "%24", "$")
        str := StrReplace(str, "%26", "&")
        str := StrReplace(str, "%27", "'")
        str := StrReplace(str, "%28", "(")
        str := StrReplace(str, "%29", ")")
        return str
    }
}
