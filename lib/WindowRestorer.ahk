; Window Restorer - Restores window layouts from saved profiles
#Include VirtualDesktop.ahk
#Include Logger.ahk
#Include ProgressIndicator.ahk
#Include ToastNotification.ahk
#Include LoadingGUI.ahk

class WindowRestorer {
    ; Restore a complete layout from window array (DESKTOP-BY-DESKTOP VERSION)
    static RestoreLayout(windows, &progressCallback := "", showProgress := false) {
        Logger.Info("========== Starting Desktop-by-Desktop Layout Restoration VERSION 4.0 ==========")
        Logger.Info("Processing each desktop sequentially - launch on target desktop")
        Logger.Info("Total windows to restore: " . windows.Length)

        ; Show loading GUI with lock
        LoadingGUI.Show("Preparing restoration...")

        try {
            restoredCount := 0
            failedCount := 0
            minimizedCount := 0
            skippedCount := 0
            totalWindows := windows.Length
            startTime := A_TickCount

            ; PHASE 1: GROUP WINDOWS BY DESKTOP
            LoadingGUI.UpdateProgress("Grouping windows by desktop...")
            Logger.Info("Phase 1: Grouping windows by desktop")

            windowsByDesktop := Map()
            maxDesktop := 1

            for windowInfo in windows {
                desktop := windowInfo["desktop"]
                if (desktop > maxDesktop) {
                    maxDesktop := desktop
                }
                if (!windowsByDesktop.Has(desktop)) {
                    windowsByDesktop[desktop] := []
                }
                windowsByDesktop[desktop].Push(windowInfo)
            }

            Logger.Info(Format("Found windows across {} desktops", maxDesktop))
            for desktop, winList in windowsByDesktop {
                Logger.Info(Format("  Desktop {}: {} windows", desktop, winList.Length))
            }

            ; Track used HWNDs across all desktops
            usedHwnds := Map()

            ; Track windows we moved in Step 0 (so we don't try to launch them)
            movedHwnds := Map()

            ; PHASE 2: PROCESS EACH DESKTOP SEQUENTIALLY
            Loop maxDesktop {
                desktopNum := A_Index
                if (!windowsByDesktop.Has(desktopNum)) {
                    Logger.Info(Format("Skipping desktop {} - no windows to restore", desktopNum))
                    continue
                }

                Logger.Info(Format("========== PROCESSING DESKTOP {} ==========", desktopNum))
                LoadingGUI.UpdateProgress(Format("Desktop {}/{}...", desktopNum, maxDesktop))

                ; Switch to this desktop
                VirtualDesktop.SwitchToDesktop(desktopNum)
                Sleep(200)

                desktopWindows := windowsByDesktop[desktopNum]

                ; STEP 0: MOVE MISPLACED WINDOWS TO THIS DESKTOP
                Logger.Info(Format("Step 0: Checking for windows that belong on desktop {} but are elsewhere", desktopNum))
                DetectHiddenWindows(false)

                ; For each window that should be on this desktop, check if it exists elsewhere
                for winInfo in desktopWindows {
                    processName := winInfo["processName"]
                    windowTitle := winInfo["windowTitle"]

                    Logger.Debug(Format("Step 0: Looking for '{}' (process: {})", windowTitle, processName))

                    try {
                        ; Get all windows for this process across ALL desktops
                        ; For apps that might be hidden/minimized, check both visible and hidden
                        ; Include: Telegram, WhatsApp (UWP), Docker, Evernote, Slack, Spotify (UWP)
                        if (InStr(processName, "Telegram.exe") ||
                            InStr(processName, "ApplicationFrameHost.exe") ||
                            InStr(processName, "Docker Desktop.exe") ||
                            InStr(processName, "Evernote.exe") ||
                            InStr(processName, "Slack.exe") ||
                            InStr(processName, "Spotify.exe")) {
                            DetectHiddenWindows(true)
                            allProcessWindows := WinGetList("ahk_exe " . processName)
                            Logger.Debug(Format("Step 0: Found {} windows (including hidden) for process {}", allProcessWindows.Length, processName))
                        } else {
                            DetectHiddenWindows(false)
                            allProcessWindows := WinGetList("ahk_exe " . processName)
                            Logger.Debug(Format("Step 0: Found {} windows for process {}", allProcessWindows.Length, processName))
                        }

                        for hwnd in allProcessWindows {
                            if (usedHwnds.Has(hwnd)) {
                                continue  ; Already used
                            }

                            ; Check which desktop this window is on
                            currentDesktop := VirtualDesktop.GetDesktopNumber(hwnd)

                            ; Get window title for debug logging
                            currentTitle := WinGetTitle("ahk_id " . hwnd)

                            ; ENHANCED DEBUG: Show if this is Docker or Evernote
                            if (InStr(processName, "Docker Desktop.exe") || InStr(processName, "Evernote.exe")) {
                                ; Get the DLL's raw return value for extra debugging
                                Logger.Info(Format("*** ENHANCED DEBUG *** Process: {} | HWND: {} | Title: '{}' | DLL Reports Desktop: {} | Target Desktop: {} | Currently On Desktop: {}", processName, hwnd, currentTitle, currentDesktop, desktopNum, VirtualDesktop.GetCurrentDesktopNumber()))
                            }

                            Logger.Debug(Format("Step 0: HWND {} - Title: '{}' - Desktop: {} - Target: {}", hwnd, currentTitle, currentDesktop, desktopNum))

                            if (currentDesktop = desktopNum || currentDesktop = 0) {
                                Logger.Debug(Format("Step 0: Skipping - already on desktop {} or sticky", currentDesktop))
                                continue  ; Already on correct desktop or sticky window
                            }

                            ; Skip hidden system windows
                            if (currentTitle = "" ||
                                InStr(currentTitle, "QTrayIcon") ||
                                InStr(currentTitle, "Default IME") ||
                                InStr(currentTitle, "GDI+ Window") ||
                                InStr(currentTitle, "MSCTFIME UI")) {
                                continue
                            }

                            ; For single-window apps (Telegram, Docker, etc.), just match by process
                            ; For multi-window apps (Chrome, Terminal, VS Code) and UWP apps (ApplicationFrameHost), match by title similarity
                            ; NOTE: ApplicationFrameHost.exe is used by ALL UWP apps, so we MUST match by title
                            ; NOTE: Chrome can have multiple windows, so match by title
                            ; Use exact process names from saved profiles for accurate matching
                            singleWindowApps := ["Telegram.exe", "Docker Desktop.exe",
                                                "claude.exe", "Spotify.exe", "Evernote.exe",
                                                "Slack.exe"]

                            isSingleWindowApp := false
                            for singleApp in singleWindowApps {
                                if (processName = singleApp) {
                                    isSingleWindowApp := true
                                    Logger.Debug(Format("Matched single-window app: {}", processName))
                                    break
                                }
                            }

                            shouldMove := false

                            if (isSingleWindowApp) {
                                ; For single-window apps, just matching process is enough
                                shouldMove := true
                                Logger.Info(Format("MOVING (process match): {} from desktop {} to desktop {}", currentTitle, currentDesktop, desktopNum))
                            } else {
                                ; For multi-window apps and UWP apps, check for title similarity
                                ; Special case for Telegram: "Telegram (42704)" should match "TelegramDesktop"
                                if (InStr(processName, "Telegram.exe") && InStr(currentTitle, "Telegram")) {
                                    shouldMove := true
                                    Logger.Info(Format("MOVING (Telegram match): {} from desktop {} to desktop {}", currentTitle, currentDesktop, desktopNum))
                                }
                                ; Match if: exact match, or current title contains expected title, or both contain "Desktop"
                                else if (currentTitle = windowTitle ||
                                    InStr(currentTitle, windowTitle) ||
                                    InStr(windowTitle, currentTitle) ||
                                    (InStr(windowTitle, "Desktop") && InStr(currentTitle, "Desktop"))) {
                                    shouldMove := true
                                    Logger.Info(Format("MOVING (title match): {} from desktop {} to desktop {}", currentTitle, currentDesktop, desktopNum))
                                }
                            }

                            if (shouldMove) {
                                ; Move window to correct desktop using DLL API
                                try {
                                    success := VirtualDesktop.MoveWindowToDesktop(hwnd, desktopNum)
                                    if (success) {
                                        Logger.Info(Format("✓ Moved {} to desktop {} (will be positioned later)", currentTitle, desktopNum))
                                        ; Track that we moved this window so we don't try to launch it again
                                        movedHwnds[hwnd] := true
                                        ; DON'T mark as used yet - window needs to be matched and positioned in Steps B & D
                                    } else {
                                        Logger.Error(Format("Failed to move {} to desktop {}", currentTitle, desktopNum))
                                    }
                                } catch as e {
                                    Logger.Error(Format("Exception moving {}: {}", currentTitle, e.Message))
                                }
                                break  ; Found and moved, stop looking for more windows of this process
                            }
                        }
                    } catch as e {
                        Logger.Debug(Format("Error checking for misplaced {}: {}", processName, e.Message))
                    }
                }

                ; Switch back to ensure we're on the right desktop and give time for moved windows to settle
                VirtualDesktop.SwitchToDesktop(desktopNum)
                Sleep(500)  ; Extra delay to ensure moved windows are properly registered

                ; STEP A: DETECT OPEN APPS ON THIS DESKTOP
                Logger.Info(Format("Step A: Detecting open apps on desktop {}", desktopNum))
                DetectHiddenWindows(false)  ; Only visible windows

                currentDesktopWindows := []
                for hwnd in WinGetList() {
                    try {
                        if (!WinExist("ahk_id " . hwnd)) {
                            continue
                        }

                        ; Check if window is on current desktop
                        winDesktop := VirtualDesktop.GetDesktopNumber(hwnd)
                        if (winDesktop != desktopNum && winDesktop != 0) {
                            continue  ; Window on different desktop
                        }

                        title := WinGetTitle("ahk_id " . hwnd)
                        if (title = "") {
                            continue
                        }

                        processName := ProcessGetName(WinGetPID("ahk_id " . hwnd))

                        ; Skip IME windows
                        if (InStr(title, "IME") || processName = "TextInputHost.exe") {
                            continue
                        }

                        WinGetPos(&x, &y, &w, &h, "ahk_id " . hwnd)
                        minMaxState := WinGetMinMax("ahk_id " . hwnd)

                        currentDesktopWindows.Push({
                            hwnd: hwnd,
                            title: title,
                            processName: processName,
                            x: x,
                            y: y,
                            w: w,
                            h: h,
                            maximized: (minMaxState = 1),
                            minimized: (minMaxState = -1)
                        })
                    } catch {
                        continue
                    }
                }

                Logger.Info(Format("Found {} windows on desktop {}", currentDesktopWindows.Length, desktopNum))

                ; STEP B: MATCH AND MINIMIZE UNWANTED WINDOWS
                Logger.Info(Format("Step B: Matching windows and minimizing unwanted ones"))

                neededProcesses := Map()
                for winInfo in desktopWindows {
                    processName := winInfo["processName"]
                    if (!neededProcesses.Has(processName)) {
                        neededProcesses[processName] := []
                    }
                    neededProcesses[processName].Push(winInfo)
                }

                ; Match existing windows to needed windows
                windowActions := []
                for winInfo in desktopWindows {
                    processName := winInfo["processName"]

                    ; Try to find matching window
                    bestMatch := 0
                    bestScore := 999999

                    for openWin in currentDesktopWindows {
                        if (openWin.processName != processName || usedHwnds.Has(openWin.hwnd)) {
                            continue
                        }

                        ; Calculate match score (lower is better)
                        dx := Abs(openWin.x - winInfo["x"])
                        dy := Abs(openWin.y - winInfo["y"])
                        dw := Abs(openWin.w - winInfo["width"])
                        dh := Abs(openWin.h - winInfo["height"])
                        maxMatch := (openWin.maximized = winInfo["maximized"]) ? 0 : 500

                        score := dx + dy + dw + dh + maxMatch

                        if (score < bestScore) {
                            bestScore := score
                            bestMatch := openWin.hwnd
                        }
                    }

                    ; DEBUG: Log Docker matching
                    if (InStr(processName, "Docker Desktop.exe")) {
                        Logger.Info(Format("DOCKER MATCH: Score={} | Match={} | Title={}", bestScore, bestMatch, winInfo["windowTitle"]))
                    }

                    ; If already perfectly positioned, skip
                    if (bestMatch && bestScore < 20) {
                        Logger.Info(Format("Window already correct: {}", winInfo["windowTitle"]))
                        usedHwnds[bestMatch] := true
                        skippedCount++
                        continue
                    }

                    ; Plan action
                    ; Force moved windows to be repositioned (not launched) even if score is high
                    if (bestMatch && (bestScore < 500 || movedHwnds.Has(bestMatch))) {
                        if (movedHwnds.Has(bestMatch)) {
                            Logger.Info(Format("Planning REPOSITION for MOVED window: {} (score: {} - ignoring score)", winInfo["windowTitle"], bestScore))
                        } else {
                            Logger.Info(Format("Planning REPOSITION for: {} (score: {})", winInfo["windowTitle"], bestScore))
                        }
                        windowActions.Push({
                            action: "reposition",
                            hwnd: bestMatch,
                            profile: winInfo
                        })
                        usedHwnds[bestMatch] := true
                    } else {
                        Logger.Info(Format("Planning LAUNCH for: {} (score: {})", winInfo["windowTitle"], bestScore))
                        windowActions.Push({
                            action: "launch",
                            profile: winInfo
                        })
                    }
                }

                ; Minimize unwanted windows on this desktop
                systemProcesses := ["TextInputHost.exe", "ShellExperienceHost.exe",
                                   "SearchHost.exe", "StartMenuExperienceHost.exe",
                                   "SystemSettings.exe", "explorer.exe", "dwm.exe",
                                   "WindowLayoutManager.exe"]

                for openWin in currentDesktopWindows {
                    if (usedHwnds.Has(openWin.hwnd)) {
                        continue
                    }

                    ; Skip system processes
                    skipWindow := false
                    for sysProc in systemProcesses {
                        if (openWin.processName = sysProc) {
                            skipWindow := true
                            break
                        }
                    }

                    if (!skipWindow) {
                        try {
                            if (WinExist("ahk_id " . openWin.hwnd)) {
                                WinMinimize("ahk_id " . openWin.hwnd)
                                minimizedCount++
                            }
                        } catch {
                            continue
                        }
                    }
                }

                ; STEP C: LAUNCH MISSING APPS (5 SECOND TIMEOUT EACH)
                Logger.Info(Format("Step C: Launching missing apps on desktop {}", desktopNum))

                launchActions := []
                for action in windowActions {
                    if (action.action = "launch") {
                        launchActions.Push(action)
                    }
                }

                if (launchActions.Length > 0) {
                    Logger.Info(Format("Need to launch {} apps", launchActions.Length))

                    ; STEP 1: Capture baseline window counts per process BEFORE any launches
                    Logger.Info("Step 1: Capturing baseline window state")
                    baselineWindows := Map()  ; processName -> Array of HWNDs

                    for action in launchActions {
                        processName := action.profile["processName"]
                        if (!baselineWindows.Has(processName)) {
                            try {
                                ; Special handling for Docker Desktop and Telegram - check for hidden windows first
                                if (InStr(processName, "Docker Desktop.exe") || InStr(processName, "Telegram.exe")) {
                                    ; Check for hidden windows that need to be shown
                                    DetectHiddenWindows(true)
                                    hiddenWindows := WinGetList("ahk_exe " . processName)
                                    if (hiddenWindows.Length > 0) {
                                        Logger.Info(Format("{} has {} hidden windows - checking for main windows", processName, hiddenWindows.Length))
                                        for hwnd in hiddenWindows {
                                            try {
                                                winTitle := WinGetTitle("ahk_id " . hwnd)

                                                ; Only show windows with meaningful titles (skip empty, system, and tray icon windows)
                                                if (winTitle != "" &&
                                                    !InStr(winTitle, "GDI+ Window") &&
                                                    !InStr(winTitle, "MSCTFIME UI") &&
                                                    !InStr(winTitle, "QTrayIcon") &&
                                                    !InStr(winTitle, "Default IME")) {
                                                    Logger.Info(Format("Found hidden window with title: {}", winTitle))

                                                    ; Restore minimized windows
                                                    if (WinGetMinMax("ahk_id " . hwnd) = -1) {
                                                        WinRestore("ahk_id " . hwnd)
                                                    }
                                                    ; Show hidden windows with titles
                                                    WinShow("ahk_id " . hwnd)
                                                    Sleep(50)
                                                }
                                            } catch {
                                                continue
                                            }
                                        }
                                        Sleep(300)  ; Wait for windows to become visible
                                    }
                                }

                                DetectHiddenWindows(false)  ; Only visible windows
                                currentWindows := WinGetList("ahk_exe " . processName)
                                baselineWindows[processName] := []
                                for hwnd in currentWindows {
                                    ; For Explorer, filter out system windows
                                    if (InStr(processName, "explorer.exe")) {
                                        try {
                                            winTitle := WinGetTitle("ahk_id " . hwnd)
                                            ; Skip Program Manager and windows with empty titles
                                            if (winTitle = "" || winTitle = "Program Manager") {
                                                Logger.Debug(Format("    Skipping system Explorer window HWND {}: '{}'", hwnd, winTitle))
                                                continue
                                            }
                                        } catch {
                                            continue
                                        }
                                    }

                                    baselineWindows[processName].Push(hwnd)
                                    ; Log each existing window's title
                                    try {
                                        winTitle := WinGetTitle("ahk_id " . hwnd)
                                        Logger.Debug(Format("    Existing HWND {}: {}", hwnd, winTitle))
                                    } catch {
                                        Logger.Debug(Format("    Existing HWND {}: <no title>", hwnd))
                                    }
                                }
                                Logger.Info(Format("Baseline: {} has {} existing VISIBLE windows", processName, baselineWindows[processName].Length))
                            } catch {
                                baselineWindows[processName] := []
                                Logger.Info(Format("Baseline: {} has 0 existing windows", processName))
                            }
                    }
                }

                ; STEP 2: Launch apps and immediately detect with fast polling
                Logger.Info("Step 2: Launching apps with immediate detection")
                remainingActions := []

                for action in launchActions {
                    ; Check global timeout before each launch
                    elapsed := A_TickCount - startTime
                    if (elapsed > 90000) {
                        Logger.Error("Global timeout reached during launch phase (90s)")
                        break
                    }

                    try {
                        processName := action.profile["processName"]
                        execPath := action.profile["executablePath"]
                        windowTitle := action.profile["windowTitle"]
                        explorerPath := action.profile.Has("explorerPath") ? action.profile["explorerPath"] : ""

                        ; Check if app is already running with unused VISIBLE windows BEFORE launching
                        alreadyRunningWithUnused := false
                        try {
                            DetectHiddenWindows(false)  ; Only visible windows
                            existingWindows := WinGetList("ahk_exe " . processName)

                            ; If app has existing visible windows beyond baseline, try to use one
                            if (existingWindows.Length > 0) {
                                for hwnd in existingWindows {
                                    if (!usedHwnds.Has(hwnd)) {
                                        ; Verify window is actually visible and usable
                                        if (WinExist("ahk_id " . hwnd)) {
                                            ; Check if window is minimized or has no title (likely hidden)
                                            winTitle := WinGetTitle("ahk_id " . hwnd)
                                            isMinimized := (WinGetMinMax("ahk_id " . hwnd) = -1)

                                            ; For Explorer, skip system windows
                                            if (InStr(processName, "explorer.exe")) {
                                                if (winTitle = "" || winTitle = "Program Manager") {
                                                    Logger.Debug(Format("Skipping system Explorer window (HWND: {}) - '{}'", hwnd, winTitle))
                                                    continue
                                                }
                                            }

                                            ; Skip minimized windows
                                            if (isMinimized) {
                                                Logger.Debug(Format("Skipping minimized window (HWND: {})", hwnd))
                                                continue
                                            }

                                            ; Found an unused visible window from an already-running process
                                            Logger.Info(Format("✓ Reusing existing visible window: {} (HWND: {}) - {}", processName, hwnd, winTitle))
                                            action.hwnd := hwnd
                                            usedHwnds[hwnd] := true
                                            alreadyRunningWithUnused := true
                                            break
                                        }
                                    }
                                }
                            }
                        } catch {
                            ; Continue with normal launch
                        }

                        ; Skip launch if we found an unused window
                        if (alreadyRunningWithUnused) {
                            ; Stagger WindowsTerminal even when reusing
                            if (InStr(processName, "WindowsTerminal.exe")) {
                                Sleep(300)
                            }
                            continue
                        }

                        ; Launch the app
                        Logger.Debug(Format("Launching: {}", processName))
                        launchSuccess := this.LaunchApplicationHidden(execPath, processName, windowTitle, explorerPath)

                        if (!launchSuccess) {
                            Logger.Error(Format("Failed to launch: {}", processName))
                            continue
                        }

                        ; Immediate detection with fast polling (10 attempts over 500ms)
                        detected := false
                        Loop 10 {
                            Sleep(50)

                            ; Check global timeout
                            elapsed := A_TickCount - startTime
                            if (elapsed > 90000) {
                                Logger.Error("Global timeout during immediate detection (90s)")
                                break 2  ; Break out of both loops
                            }

                            ; Get current VISIBLE windows for this process
                            try {
                                DetectHiddenWindows(false)  ; Only visible windows
                                currentWindows := WinGetList("ahk_exe " . processName)

                                ; Check if we have NEW visible windows beyond baseline
                                if (currentWindows.Length > baselineWindows[processName].Length) {
                                    ; Find the new window(s)
                                    for hwnd in currentWindows {
                                        isNew := true
                                        for baselineHwnd in baselineWindows[processName] {
                                            if (hwnd = baselineHwnd) {
                                                isNew := false
                                                break
                                            }
                                        }

                                        if (isNew && !usedHwnds.Has(hwnd)) {
                                            ; For Explorer, filter out system windows during detection
                                            if (InStr(processName, "explorer.exe")) {
                                                try {
                                                    winTitle := WinGetTitle("ahk_id " . hwnd)
                                                    if (winTitle = "" || winTitle = "Program Manager") {
                                                        Logger.Debug(Format("Skipping system Explorer during detection (HWND: {}) - '{}'", hwnd, winTitle))
                                                        continue
                                                    }
                                                } catch {
                                                    continue
                                                }
                                            }

                                            Logger.Info(Format("✓ Detected immediately: {} (HWND: {})", processName, hwnd))
                                            action.hwnd := hwnd
                                            usedHwnds[hwnd] := true
                                            baselineWindows[processName].Push(hwnd)  ; Update baseline
                                            detected := true
                                            break
                                        }
                                    }

                                    if (detected) {
                                        break
                                    }
                                }
                            } catch as e {
                                Logger.Debug(Format("Detection error: {}", e.Message))
                                continue
                            }
                        }

                        if (!detected) {
                            Logger.Warn(Format("⏱ Not detected immediately: {} - adding to fallback queue", processName))
                            remainingActions.Push(action)
                        }

                        ; Stagger WindowsTerminal launches
                        if (InStr(processName, "WindowsTerminal.exe")) {
                            Sleep(300)
                        }
                    } catch as e {
                        Logger.Error(Format("Error during launch: {}", e.Message))
                    }
                }

                ; STEP 3: Fast polling (5 SECOND TIMEOUT) for remaining apps
                if (remainingActions.Length > 0) {
                    Logger.Info(Format("Step 3: Waiting up to 5s for {} remaining apps", remainingActions.Length))

                    pollStart := A_TickCount
                    maxPollTime := 5000  ; 5 SECOND TIMEOUT per desktop

                    while (remainingActions.Length > 0) {
                        ; Check 5-second timeout
                        if ((A_TickCount - pollStart) > maxPollTime) {
                            Logger.Warn(Format("✗ {} apps not detected after 5 seconds - SKIPPING", remainingActions.Length))
                            for action in remainingActions {
                                Logger.Warn(Format("  - SKIPPED: {}", action.profile["processName"]))
                                failedCount++
                            }
                            break
                        }

                        Sleep(50)

                        ; Check each remaining action
                        i := remainingActions.Length
                        while (i > 0) {
                            action := remainingActions[i]
                            processName := action.profile["processName"]

                            try {
                                DetectHiddenWindows(false)  ; Only visible windows
                                currentWindows := WinGetList("ahk_exe " . processName)

                                ; Check if we have NEW visible windows beyond baseline
                                if (currentWindows.Length > baselineWindows[processName].Length) {
                                    ; Find the new window
                                    for hwnd in currentWindows {
                                        isNew := true
                                        for baselineHwnd in baselineWindows[processName] {
                                            if (hwnd = baselineHwnd) {
                                                isNew := false
                                                break
                                            }
                                        }

                                        if (isNew && !usedHwnds.Has(hwnd)) {
                                            ; For Explorer, filter out system windows during detection
                                            if (InStr(processName, "explorer.exe")) {
                                                try {
                                                    winTitle := WinGetTitle("ahk_id " . hwnd)
                                                    if (winTitle = "" || winTitle = "Program Manager") {
                                                        Logger.Debug(Format("Skipping system Explorer in fallback (HWND: {}) - '{}'", hwnd, winTitle))
                                                        continue
                                                    }
                                                } catch {
                                                    continue
                                                }
                                            }

                                            Logger.Info(Format("✓ Detected: {} (HWND: {})", processName, hwnd))
                                            action.hwnd := hwnd
                                            usedHwnds[hwnd] := true
                                            baselineWindows[processName].Push(hwnd)
                                            remainingActions.RemoveAt(i)
                                            break
                                        }
                                    }
                                }
                            } catch {
                                ; Continue to next action
                            }

                            i--
                        }
                    }
                }
                }

                ; STEP D: POSITION ALL WINDOWS ON THIS DESKTOP
                Logger.Info(Format("Step D: Positioning windows on desktop {}", desktopNum))

                for action in windowActions {
                    if (!action.HasOwnProp("hwnd") || !action.hwnd) {
                        continue
                    }

                    try {
                        hwnd := action.hwnd
                        profile := action.profile

                        ; Verify window still exists
                        if (!WinExist("ahk_id " . hwnd)) {
                            continue
                        }

                        ; Restore if minimized
                        if (WinGetMinMax("ahk_id " . hwnd) = -1) {
                            WinRestore("ahk_id " . hwnd)
                            Sleep(50)
                        }

                        ; Apply size and position
                        if (profile["maximized"]) {
                            if (WinGetMinMax("ahk_id " . hwnd) != 1) {
                                WinMaximize("ahk_id " . hwnd)
                            }
                        } else {
                            if (WinGetMinMax("ahk_id " . hwnd) = 1) {
                                WinRestore("ahk_id " . hwnd)
                                Sleep(50)
                            }
                            WinMove(profile["x"], profile["y"], profile["width"], profile["height"], "ahk_id " . hwnd)
                        }

                        restoredCount++
                        Logger.Debug(Format("Positioned: {}", profile["windowTitle"]))
                    } catch as e {
                        Logger.Error(Format("Failed to position {}: {}", action.profile["windowTitle"], e.Message))
                        failedCount++
                    }
                }

                ; Clean up IME windows on this desktop
                try {
                    imeWindows := WinGetList("ahk_exe TextInputHost.exe")
                    for imeHwnd in imeWindows {
                        WinHide("ahk_id " . imeHwnd)
                    }
                } catch {
                    ; Ignore cleanup errors
                }

                Logger.Info(Format("Desktop {} complete", desktopNum))
            }

            ; FINAL: Return to desktop 1 and cleanup
            Logger.Info("Returning to desktop 1")
            VirtualDesktop.SwitchToDesktop(1)
            Sleep(200)

            elapsed := A_TickCount - startTime
            Logger.Info(Format("========== Restoration Complete in {}ms ==========", elapsed))
            Logger.Info(Format("Restored: {} | Skipped: {} | Failed: {} | Minimized: {}", restoredCount, skippedCount, failedCount, minimizedCount))

            ; Hide loading GUI
            LoadingGUI.Hide()

            ; Show quick completion notification
            try {
                ToastNotification.Success(Format("✓ Complete in {}s - {} restored", elapsed // 1000, restoredCount))
            } catch {
                ; Toast notification failed
            }

            return { restored: restoredCount, failed: failedCount, total: totalWindows, minimized: minimizedCount, skipped: skippedCount }

        } catch as e {
            ; Ensure loading GUI is hidden on error
            LoadingGUI.ForceHide()
            Logger.Error(Format("Error during restoration: {}", e.Message))
            MsgBox("Error during restoration: " . e.Message, "Error", "Icon!")
            return { restored: 0, failed: totalWindows, total: totalWindows, minimized: 0, skipped: 0 }
        }
    }

    ; Pre-match existing windows to profile windows by position proximity
    static PreMatchWindowsByPosition(profileWindows, usedHwnds) {
        matches := Map()

        ; Group profile windows by process
        processList := Map()
        for profileWin in profileWindows {
            processName := profileWin["processName"]
            if (!processList.Has(processName)) {
                processList[processName] := []
            }
            processList[processName].Push(profileWin)
        }

        ; For each process, match existing windows to profile windows by proximity
        for processName, profileWinList in processList {
            ; Get all existing windows for this process
            try {
                existingWindows := WinGetList("ahk_exe " . processName)
                if (existingWindows.Length = 0) {
                    continue
                }

                ; Build list of existing windows with their positions
                existingList := []
                for hwnd in existingWindows {
                    ; Skip already used windows
                    if (usedHwnds.Has(hwnd)) {
                        continue
                    }

                    try {
                        WinGetPos(&x, &y, &w, &h, "ahk_id " . hwnd)
                        existingList.Push({hwnd: hwnd, x: x, y: y, w: w, h: h})
                    }
                }

                ; Match each existing window to closest profile window
                for existing in existingList {
                    bestMatch := 0
                    bestDistance := 999999

                    for profileWin in profileWinList {
                        ; Skip if this profile window is already matched
                        if (matches.Has(profileWin)) {
                            continue
                        }

                        ; Calculate distance (simple Manhattan distance)
                        dx := Abs(existing.x - profileWin["x"])
                        dy := Abs(existing.y - profileWin["y"])
                        distance := dx + dy

                        if (distance < bestDistance) {
                            bestDistance := distance
                            bestMatch := profileWin
                        }
                    }

                    ; If we found a good match (within reasonable distance), use it
                    if (bestMatch && bestDistance < 500) {  ; 500 pixels tolerance
                        matches[bestMatch] := existing.hwnd
                    }
                }
            }
        }

        return matches
    }

    ; Restore a window fast (assumes app is already launched, just position it)
    static RestoreWindowFast(windowInfo, usedHwnds, preMatchedHwnd := 0) {
        try {
            processName := windowInfo["processName"]
            windowTitle := windowInfo["windowTitle"]
            x := windowInfo["x"]
            y := windowInfo["y"]
            width := windowInfo["width"]
            height := windowInfo["height"]
            maximized := windowInfo["maximized"]
            targetDesktop := windowInfo["desktop"]

            ; Use pre-matched window if available, otherwise find by title
            ; Note: We're already on the target desktop, so FindMatchingWindow only finds windows on THIS desktop
            hwnd := preMatchedHwnd
            if (!hwnd) {
                hwnd := this.FindMatchingWindow(processName, windowTitle, usedHwnds)
            }

            ; If window doesn't exist on this desktop, skip it (it may be on wrong desktop or failed to launch)
            if (!hwnd) {
                Logger.Warn(Format("Window not found on desktop {}: {} ({})", targetDesktop, windowTitle, processName))
                return false
            }

            ; Mark this HWND as used
            usedHwnds[hwnd] := true

            ; Verify window still exists before operating on it
            if (!WinExist("ahk_id " . hwnd)) {
                Logger.Warn(Format("Window disappeared before positioning: {} (HWND: {})", windowTitle, hwnd))
                return false
            }

            ; Restore window if minimized
            try {
                if (WinGetMinMax("ahk_id " . hwnd) = -1) {
                    WinRestore("ahk_id " . hwnd)
                    Sleep(50)
                }
            } catch as e {
                Logger.Warn(Format("Could not restore window {}: {}", windowTitle, e.Message))
                return false
            }

            ; Position and size the window
            if (maximized) {
                try {
                    currentMaximized := (WinGetMinMax("ahk_id " . hwnd) = 1)
                    if (!currentMaximized) {
                        WinMaximize("ahk_id " . hwnd)
                    }
                } catch as e {
                    Logger.Warn(Format("Could not maximize window {}: {}", windowTitle, e.Message))
                    return false
                }
            } else {
                try {
                    if (WinGetMinMax("ahk_id " . hwnd) = 1) {
                        WinRestore("ahk_id " . hwnd)
                        Sleep(50)
                    }

                    ; Verify window exists before move
                    if (!WinExist("ahk_id " . hwnd)) {
                        Logger.Warn(Format("Window disappeared before WinMove: {}", windowTitle))
                        return false
                    }

                    WinMove(x, y, width, height, "ahk_id " . hwnd)
                } catch as e {
                    Logger.Warn(Format("Could not move window {}: {}", windowTitle, e.Message))
                    return false
                }
            }

            return true
        } catch as e {
            Logger.Error(Format("Error in RestoreWindowFast: {}", e.Message))
            return false
        }
    }

    ; Restore a single window (legacy method with launching)
    static RestoreWindow(windowInfo, usedHwnds, processCountMap, preMatchedHwnd := 0) {
        try {
            processName := windowInfo["processName"]
            windowTitle := windowInfo["windowTitle"]
            x := windowInfo["x"]
            y := windowInfo["y"]
            width := windowInfo["width"]
            height := windowInfo["height"]
            maximized := windowInfo["maximized"]
            execPath := windowInfo["executablePath"]
            targetDesktop := windowInfo["desktop"]

            Logger.Info("--------------------------------------------------")
            Logger.Info(Format("Restoring: {} ({})", windowTitle, processName))
            Logger.Info(Format("Target Desktop: {} | Position: {},{} | Size: {}x{}", targetDesktop, x, y, width, height))

            ; Use pre-matched window if available, otherwise find by title
            hwnd := preMatchedHwnd
            if (!hwnd) {
                hwnd := this.FindMatchingWindow(processName, windowTitle, usedHwnds)
            }

            ; If window doesn't exist, check if we should launch it
            if (!hwnd) {
                ; Get current count of windows for this process
                allWindows := WinGetList("ahk_exe " . processName)
                currentCount := allWindows.Length

                ; Get how many we need from the profile
                neededCount := processCountMap[processName]

                ; Count how many we've already used
                usedCount := 0
                for hwndKey, _ in usedHwnds {
                    try {
                        if (ProcessGetName(WinGetPID("ahk_id " . hwndKey)) = processName) {
                            usedCount++
                        }
                    }
                }

                Logger.Debug(Format("App not found: {} | Current: {} | Needed: {} | Used: {}", processName, currentCount, neededCount, usedCount))

                ; Launch if we don't have enough windows total for this process
                if (currentCount < neededCount) {
                    Logger.Info(Format("Launching application: {} ({})", windowTitle, processName))
                    hwnd := this.LaunchApplication(execPath, processName, windowTitle)
                    if (!hwnd) {
                        Logger.Error(Format("Failed to launch: {} ({})", windowTitle, processName))
                        return false
                    }
                    Logger.Info(Format("Successfully launched: {} (HWND: {})", windowTitle, hwnd))
                } else {
                    ; We have enough windows for this process, skip this one
                    Logger.Warn(Format("Skipping '{}' - process has enough windows ({}/{})", windowTitle, currentCount, neededCount))
                    return false
                }
            }

            ; Mark this HWND as used
            usedHwnds[hwnd] := true

            ; Get current window position
            ; Note: We can't reliably detect which desktop a window is on using COM API
            ; So we assume all windows start on desktop 1 and track movements
            WinGetPos(&currentX, &currentY, &currentWidth, &currentHeight, "ahk_id " . hwnd)
            currentMaximized := (WinGetMinMax("ahk_id " . hwnd) = 1)

            ; Assume window is on desktop 1 (we'll move it if needed)
            currentDesktop := 1

            Logger.Info(Format("Assuming Desktop: {} | Position: {},{} | Size: {}x{} | Max: {}", currentDesktop, currentX, currentY, currentWidth, currentHeight, currentMaximized))

            ; Check if window is already in the correct position and desktop
            positionMatches := (Abs(currentX - x) < 10 && Abs(currentY - y) < 10 &&
                               Abs(currentWidth - width) < 10 && Abs(currentHeight - height) < 10)
            desktopMatches := (currentDesktop = targetDesktop)
            maximizedMatches := (currentMaximized = maximized)

            ; If everything matches, skip this window (already correctly positioned)
            if (positionMatches && desktopMatches && maximizedMatches) {
                return true
            }

            ; Move window to correct desktop if needed
            if (currentDesktop != targetDesktop) {
                Logger.Info(Format("Moving window '{}' from desktop {} to desktop {}", windowTitle, currentDesktop, targetDesktop))

                ; Activate window and move it to correct desktop
                WinActivate("ahk_id " . hwnd)
                Sleep(150)

                ; Calculate how many times to move left or right
                diff := targetDesktop - currentDesktop
                Logger.Debug(Format("Desktop diff: {}", diff))

                if (diff > 0) {
                    ; Move right (to higher desktop number)
                    Loop diff {
                        Logger.Debug(Format("Sending Win+Ctrl+Right (iteration {} of {})", A_Index, diff))
                        Send("#^{Right}")
                        Sleep(300)  ; Increased delay for reliability
                    }
                } else if (diff < 0) {
                    ; Move left (to lower desktop number)
                    Loop Abs(diff) {
                        Logger.Debug(Format("Sending Win+Ctrl+Left (iteration {} of {})", A_Index, Abs(diff)))
                        Send("#^{Left}")
                        Sleep(300)  ; Increased delay for reliability
                    }
                }

                ; Wait for desktop switch to complete
                Sleep(300)

                Logger.Info("Desktop move command sent successfully")

                ; Recalculate position after desktop change
                Sleep(100)
                WinGetPos(&currentX, &currentY, &currentWidth, &currentHeight, "ahk_id " . hwnd)
                positionMatches := (Abs(currentX - x) < 10 && Abs(currentY - y) < 10 &&
                                   Abs(currentWidth - width) < 10 && Abs(currentHeight - height) < 10)
            }

            ; Restore window if minimized
            if (WinGetMinMax("ahk_id " . hwnd) = -1) {
                WinRestore("ahk_id " . hwnd)
                Sleep(100)
            }

            ; Position and size the window only if needed
            if (maximized) {
                if (!currentMaximized) {
                    WinMaximize("ahk_id " . hwnd)
                }
            } else {
                ; First restore if maximized
                if (WinGetMinMax("ahk_id " . hwnd) = 1) {
                    WinRestore("ahk_id " . hwnd)
                    Sleep(100)
                }

                ; Move and resize only if position doesn't match
                if (!positionMatches) {
                    WinMove(x, y, width, height, "ahk_id " . hwnd)
                }
            }

            Sleep(50)
            return true
        } catch as e {
            return false
        }
    }

    ; Find a matching window by process and title (only on current desktop)
    static FindMatchingWindow(processName, windowTitle, usedHwnds) {
        try {
            ; Get all windows on current desktop
            allWindows := WinGetList()

            ; Filter by process name
            processWindows := []
            for hwnd in allWindows {
                try {
                    if (ProcessGetName(WinGetPID("ahk_id " . hwnd)) = processName) {
                        processWindows.Push(hwnd)
                    }
                }
            }

            if (processWindows.Length = 0) {
                return 0
            }

            ; Try to find best match by title similarity, excluding used windows
            bestMatch := 0
            bestScore := 0

            for hwnd in processWindows {
                ; Skip if this window is already used
                if (usedHwnds.Has(hwnd)) {
                    continue
                }

                currentTitle := WinGetTitle("ahk_id " . hwnd)

                ; Check for exact match first
                if (currentTitle = windowTitle) {
                    return hwnd
                }

                ; Calculate similarity score
                score := this.CalculateTitleSimilarity(windowTitle, currentTitle)

                if (score > bestScore) {
                    bestScore := score
                    bestMatch := hwnd
                }
            }

            ; Return best match if we found any similarity, or first unused window
            if (bestMatch) {
                return bestMatch
            }

            ; If no good match, return first unused window of this process
            for hwnd in processWindows {
                if (!usedHwnds.Has(hwnd)) {
                    return hwnd
                }
            }

            return 0
        } catch {
            return 0
        }
    }

    ; Calculate similarity between two titles (simple implementation)
    static CalculateTitleSimilarity(title1, title2) {
        ; Simple similarity: how many words match
        words1 := StrSplit(title1, " ")
        words2 := StrSplit(title2, " ")
        matches := 0

        for word1 in words1 {
            for word2 in words2 {
                if (word1 = word2 && StrLen(word1) > 2) {
                    matches++
                }
            }
        }

        return matches
    }

    ; Launch an application hidden/minimized (for optimized restoration)
    static LaunchApplicationHidden(execPath, processName, windowTitle := "", explorerPath := "") {
        try {
            Logger.Info(Format("Launching hidden: {} - {}", processName, windowTitle))

            ; Save current DetectHiddenWindows state
            vDHW := A_DetectHiddenWindows
            DetectHiddenWindows(true)

            ; Try to launch Store apps (UWP apps) using shell:AppsFolder
            ; Check for ApplicationFrameHost OR WindowsApps path
            ; EXCEPT Windows Terminal - launch that normally
            if ((InStr(processName, "ApplicationFrameHost.exe") || InStr(execPath, "WindowsApps")) && !InStr(processName, "WindowsTerminal.exe")) {
                Logger.Info("Detected WindowsApps path, will try shell:AppsFolder: " . windowTitle)
                this.LaunchUWPApp(windowTitle, processName)
                DetectHiddenWindows(vDHW)
                return true
            }

            ; Special handling for Docker Desktop - check for hidden windows
            if (InStr(processName, "Docker Desktop.exe")) {
                ; Enable hidden window detection for Docker
                DetectHiddenWindows(true)
                dockerWindows := WinGetList("ahk_exe " . processName)

                if (dockerWindows.Length > 0) {
                    Logger.Info(Format("Docker Desktop process already running with {} windows", dockerWindows.Length))

                    ; Try to find and restore/show only main Docker windows (not system windows)
                    for dockerHwnd in dockerWindows {
                        try {
                            dockerTitle := WinGetTitle("ahk_id " . dockerHwnd)

                            ; Skip empty titles, system windows, and tray icon windows
                            if (dockerTitle = "" ||
                                InStr(dockerTitle, "GDI+ Window") ||
                                InStr(dockerTitle, "MSCTFIME UI") ||
                                InStr(dockerTitle, "QTrayIcon") ||
                                InStr(dockerTitle, "Default IME")) {
                                continue
                            }

                            Logger.Info(Format("Found Docker window with title: {}", dockerTitle))
                            minMaxState := WinGetMinMax("ahk_id " . dockerHwnd)

                            ; If window is minimized, restore it
                            if (minMaxState = -1) {
                                Logger.Info(Format("Restoring minimized Docker window: {}", dockerTitle))
                                WinRestore("ahk_id " . dockerHwnd)
                                Sleep(100)
                            }

                            ; Show hidden Docker windows (only those with titles)
                            if (!WinGetStyle("ahk_id " . dockerHwnd) & 0x10000000) {  ; WS_VISIBLE
                                Logger.Info(Format("Showing hidden Docker window: {}", dockerTitle))
                                WinShow("ahk_id " . dockerHwnd)
                                Sleep(100)
                            }
                        } catch {
                            continue
                        }
                    }

                    ; Docker is running - window will be found and positioned by RestoreLayout
                    DetectHiddenWindows(vDHW)
                    return true
                }

                ; Docker not running - SKIP LAUNCHING (only reposition if already running)
                Logger.Info("Docker Desktop not running - skipping launch (will only reposition if running)")
                DetectHiddenWindows(vDHW)
                return false  ; Return false to skip this window
            }

            ; Special handling for Chrome - always launch new window with default profile
            if (InStr(processName, "chrome.exe")) {
                Logger.Info("Launching Chrome with default profile")
                ; Always launch a new Chrome window - even if Chrome is already running
                ; This ensures we get the exact number of windows needed
                if (FileExist(execPath)) {
                    Run(execPath . " --profile-directory=Default")
                } else {
                    Run("chrome.exe --profile-directory=Default")
                }
                ; Window will be detected in the wait loop
                DetectHiddenWindows(vDHW)
                return true
            }

            ; Special handling for Windows Terminal - force new window with -w -1 parameter
            if (InStr(processName, "WindowsTerminal.exe")) {
                Logger.Info("Launching Windows Terminal with -w -1 flag (force new window)")
                if (FileExist(execPath)) {
                    Run(execPath . " -w -1")
                } else {
                    Run("wt.exe -w -1")
                }
                ; Window will be detected in the wait loop
                DetectHiddenWindows(vDHW)
                return true
            }

            ; Special handling for Explorer - launch with saved folder path
            if (InStr(processName, "explorer.exe")) {
                Logger.Info(Format("Launching Explorer window: {}", windowTitle))

                ; Use the saved explorerPath from the profile, or fallback to Documents
                folderPath := (explorerPath && explorerPath != "") ? explorerPath : A_MyDocuments

                Logger.Debug(Format("Opening Explorer to: {}", folderPath))

                ; Launch Explorer with the folder path
                if (FileExist(folderPath)) {
                    Run('explorer.exe "' . folderPath . '"')
                } else {
                    ; Fallback to Documents if path doesn't exist
                    Logger.Warn(Format("Explorer path doesn't exist: {}, using Documents", folderPath))
                    Run('explorer.exe "' . A_MyDocuments . '"')
                }

                DetectHiddenWindows(vDHW)
                return true
            }

            ; Launch app normally (detection requires visible windows)
            if (FileExist(execPath)) {
                Run(execPath)
                ; Window will be detected in the wait loop
            } else {
                Run(processName)
                ; Window will be detected in the wait loop
            }

            DetectHiddenWindows(vDHW)
            return true
        } catch as e {
            Logger.Error(Format("Exception launching hidden {}: {}", processName, e.Message))
            return false
        }
    }

    ; Launch an application asynchronously (non-blocking, for parallel launches)
    static LaunchApplicationAsync(execPath, processName, windowTitle := "") {
        try {
            Logger.Info(Format("Launching (async): {} - {}", processName, windowTitle))

            ; Try to launch Store apps (UWP apps) using shell:AppsFolder
            ; Check for ApplicationFrameHost OR WindowsApps path
            if (InStr(processName, "ApplicationFrameHost.exe") || InStr(execPath, "WindowsApps")) {
                Logger.Info("Detected WindowsApps path, will try shell:AppsFolder: " . windowTitle)
                this.LaunchUWPApp(windowTitle, processName)
                return true
            }

            ; Special handling for Docker Desktop - if already running, just show the window
            if (InStr(processName, "Docker Desktop.exe")) {
                ; Check if Docker is already running
                dockerWindows := WinGetList("ahk_exe " . processName)
                if (dockerWindows.Length > 0) {
                    Logger.Info("Docker Desktop already running, activating window")
                    ; Try to activate any Docker Desktop window
                    for hwnd in dockerWindows {
                        try {
                            WinActivate("ahk_id " . hwnd)
                            WinRestore("ahk_id " . hwnd)
                            return true
                        }
                    }
                }
                ; If not running, launch it
                if (FileExist(execPath)) {
                    Run(execPath)
                } else {
                    Run(processName)
                }
                return true
            }

            ; Special handling for Chrome
            if (InStr(processName, "chrome.exe")) {
                chromeArgs := " --profile-directory=Default"
                if (FileExist(execPath)) {
                    Run(execPath . chromeArgs)
                } else {
                    Run("chrome.exe" . chromeArgs)
                }
                return true
            }

            ; Try to run the executable normally
            if (FileExist(execPath)) {
                Run(execPath)
            } else {
                Run(processName)
            }
            return true
        } catch as e {
            Logger.Error(Format("Exception launching (async) {}: {}", processName, e.Message))
            return false
        }
    }

    ; Launch an application (legacy method, kept for compatibility)
    static LaunchApplication(execPath, processName, windowTitle := "") {
        try {
            Logger.Info(Format("Attempting to launch: {}", execPath))

            ; Try to launch Store apps (UWP apps) using shell:AppsFolder
            ; Check for ApplicationFrameHost OR WindowsApps path
            if (InStr(processName, "ApplicationFrameHost.exe") || InStr(execPath, "WindowsApps")) {
                Logger.Info("Detected Store app, attempting to launch via shell:AppsFolder")
                if (this.LaunchUWPApp(windowTitle, processName)) {
                    return this.WaitForNewWindow(processName, WinGetList("ahk_exe " . processName).Length)
                } else {
                    Logger.Warn("Could not launch Store app: " . windowTitle)
                    return 0
                }
            }

            initialWindowCount := WinGetList("ahk_exe " . processName).Length

            ; Special handling for Chrome to use Default profile and skip profile picker
            if (InStr(processName, "chrome.exe")) {
                chromeArgs := " --profile-directory=Default"
                if (FileExist(execPath)) {
                    Logger.Debug("Launching Chrome with path: " . execPath)
                    Run(execPath . chromeArgs)
                } else {
                    Logger.Debug("Launching Chrome with default command")
                    Run("chrome.exe" . chromeArgs)
                }
            }
            ; Try to run the executable normally for other apps
            else if (FileExist(execPath)) {
                Logger.Debug("Launching with path: " . execPath)
                Run(execPath)
            } else {
                ; Try just the process name
                Logger.Debug("Path not found, trying process name: " . processName)
                Run(processName)
            }

            ; Wait for window to appear
            return this.WaitForNewWindow(processName, initialWindowCount)
        } catch as e {
            Logger.Error(Format("Exception launching {}: {}", processName, e.Message))
            return 0
        }
    }

    ; Get all currently open, visible windows (excluding system windows)
    static GetAllOpenWindows() {
        openWindows := []

        try {
            ; Get all windows
            allWindows := WinGetList()

            for hwnd in allWindows {
                try {
                    ; Check if window is visible and not minimized
                    if (!WinExist("ahk_id " . hwnd)) {
                        continue
                    }

                    ; Skip if minimized
                    if (WinGetMinMax("ahk_id " . hwnd) = -1) {
                        continue
                    }

                    ; Get window title
                    title := WinGetTitle("ahk_id " . hwnd)

                    ; Skip windows without titles (usually system windows)
                    if (title = "") {
                        continue
                    }

                    ; Get process name
                    try {
                        processName := ProcessGetName(WinGetPID("ahk_id " . hwnd))
                    } catch {
                        continue
                    }

                    ; Skip Windows system processes
                    systemProcesses := ["TextInputHost.exe", "ShellExperienceHost.exe",
                                       "SearchHost.exe", "StartMenuExperienceHost.exe",
                                       "ApplicationFrameHost.exe", "SystemSettings.exe",
                                       "Taskmgr.exe", "explorer.exe", "dwm.exe",
                                       "WindowLayoutManager.exe"]

                    skipWindow := false
                    for sysProc in systemProcesses {
                        if (processName = sysProc) {
                            skipWindow := true
                            break
                        }
                    }

                    if (skipWindow) {
                        continue
                    }

                    ; Add to list
                    openWindows.Push(hwnd)
                } catch {
                    continue
                }
            }
        } catch {
            ; Return empty list on error
        }

        return openWindows
    }

    ; Launch a UWP/Store app by searching shell:AppsFolder
    static LaunchUWPApp(windowTitle, processName) {
        try {
            Logger.Info(Format("Searching for UWP app: {}", windowTitle))

            ; Search for the app in shell:AppsFolder by name
            shell := ComObject("Shell.Application")
            folder := shell.NameSpace("shell:AppsFolder")

            if (!folder) {
                Logger.Error("Could not access shell:AppsFolder")
                return false
            }

            items := folder.Items()

            ; Try exact match first
            for item in items {
                try {
                    itemName := item.Name
                    if (itemName = windowTitle) {
                        Logger.Info(Format("Found exact match for UWP app: {}", windowTitle))
                        itemPath := item.Path
                        Run("explorer shell:appsFolder\" . itemPath)
                        return true
                    }
                } catch {
                    continue
                }
            }

            ; Try partial match if exact match fails
            for item in items {
                try {
                    itemName := item.Name
                    if (InStr(itemName, windowTitle)) {
                        Logger.Info(Format("Found partial match for UWP app: {} -> {}", windowTitle, itemName))
                        itemPath := item.Path
                        Run("explorer shell:appsFolder\" . itemPath)
                        return true
                    }
                } catch {
                    continue
                }
            }

            ; Try searching by removing extra words from title
            titleWords := StrSplit(windowTitle, " ")
            if (titleWords.Length > 0) {
                firstWord := titleWords[1]
                for item in items {
                    try {
                        itemName := item.Name
                        if (InStr(itemName, firstWord)) {
                            Logger.Info(Format("Found word match for UWP app: {} -> {}", firstWord, itemName))
                            itemPath := item.Path
                            Run("explorer shell:appsFolder\" . itemPath)
                            return true
                        }
                    } catch {
                        continue
                    }
                }
            }

            ; Try searching by process name (for Spotify: "Spotify.exe" -> search for "Spotify")
            if (InStr(processName, ".exe")) {
                appNameFromProcess := StrReplace(processName, ".exe", "")
                for item in items {
                    try {
                        itemName := item.Name
                        if (InStr(itemName, appNameFromProcess)) {
                            Logger.Info(Format("Found process name match for UWP app: {} -> {}", appNameFromProcess, itemName))
                            itemPath := item.Path
                            Run("explorer shell:appsFolder\" . itemPath)
                            return true
                        }
                    } catch {
                        continue
                    }
                }
            }

            Logger.Warn(Format("Could not find UWP app in shell:AppsFolder: {}", windowTitle))
            return false
        } catch as e {
            Logger.Error(Format("Error launching UWP app: {}", e.Message))
            return false
        }
    }

    ; Wait for a new window to appear for a process
    static WaitForNewWindow(processName, initialWindowCount, customTimeout := 0) {
        ; Default timeout is 15 seconds
        timeout := 15000

        ; Special handling for slow-starting applications
        if (customTimeout > 0) {
            timeout := customTimeout
        } else if (InStr(processName, "Docker Desktop.exe")) {
            timeout := 60000  ; 60 seconds for Docker Desktop
            Logger.Info("Using extended timeout (60s) for Docker Desktop")
        } else if (InStr(processName, "Teams.exe") || InStr(processName, "Outlook.exe")) {
            timeout := 30000  ; 30 seconds for Teams/Outlook
            Logger.Info(Format("Using extended timeout (30s) for {}", processName))
        }

        startTime := A_TickCount

        while ((A_TickCount - startTime) < timeout) {
            Sleep(500)

            ; Look for new window from this process
            windows := WinGetList("ahk_exe " . processName)
            if (windows.Length > initialWindowCount) {
                Logger.Debug(Format("New window detected for {} (count: {})", processName, windows.Length))
                ; Return the most recently created window
                return windows[windows.Length]
            }
        }

        Logger.Warn(Format("Timeout waiting for {} to start (waited {}ms)", processName, timeout))
        return 0
    }

}
