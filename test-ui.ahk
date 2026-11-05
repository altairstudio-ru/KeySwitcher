#Requires AutoHotkey v2.0
#SingleInstance Force

fixtureDir := A_Temp "\KeySwitcher-ui-" DllCall("GetCurrentProcessId")
DirCreate(fixtureDir)
global cfg := {
    iniPath: fixtureDir "\config.ini", hotkey: "^+X", hotkeyCopy: "^!+X",
    autoPaste: 1, sound: 0, restore: 0, switchLayout: 0, tooltipMs: 2500, copyKey: "^c"
}
#Include "layout-map.ahk"
#Include "src\ui.ahk"

; Preview flags affect only this isolated fixture, never the user's settings.
for arg in A_Args {
    if arg = "--light" || arg = "--dark"
        IniWrite(SubStr(arg,3),cfg.iniPath,"Appearance","Theme")
    if arg = "--solid"
        IniWrite("solid",cfg.iniPath,"Appearance","Material")
}

RunConvert(copyOnly := false) {
    ToastManager.Show(copyOnly ? "Тест: копирование" : "Тест: вставка")
}

Assert(condition, message) {
    if !condition
        throw Error(message)
}

OnExit((*) => DirDelete(fixtureDir, true))
Hotkey(cfg.hotkey, (*) => RunConvert(false))
Hotkey(cfg.hotkeyCopy, (*) => RunConvert(true))
IniWrite(cfg.hotkey, cfg.iniPath, "Hotkeys", "Hotkey")
IniWrite(cfg.hotkeyCopy, cfg.iniPath, "Hotkeys", "HotkeyCopyOnly")

if A_Args.Length && A_Args[1] = "--smoke" {
    resultPath := ""
    for i, arg in A_Args {
        if arg = "--result" && i < A_Args.Length
            resultPath := A_Args[i + 1]
    }
    report(text) {
        if resultPath != ""
            FileAppend(text "`n", resultPath)
        try FileAppend(text "`n", "*")
    }
    try {
        pairs := 0, failures := 0
        SelfTest(&pairs, &failures)
        Assert(failures = 0, "layout map")
        Assert(UI_HotkeyToDisplay("^!+X") = "Ctrl + Alt + Shift + X", "hotkey display")
        Assert(UI_HotkeyToSend("^Insert") = "^{Insert}", "named copy key send syntax")
        Assert(UI_HotkeyToSend("^{Insert}") = "^{Insert}", "legacy copy key send syntax")
        Assert(UI_NormalizeHotkey("^Esc") = UI_NormalizeHotkey("^Escape"), "hotkey aliases")
        report("CHECK: opening About")
        aboutWindow := UI_ShowAbout()
        report("CHECK: closing About")
        aboutWindow.Destroy()
        report("CHECK: opening Settings")
        settingsWindow := UI_ShowSettings()
        report("CHECK: Settings opened")
        Assert(settingsWindow._Panels["hotkeys"].Visible, "initial hotkeys tab")
        Assert(!settingsWindow._Panels["main"].Visible, "main tab initially hidden")
        autoToggle := settingsWindow._Panels["main"].Auto
        SendMessage(0xF5,0,0,autoToggle.Control.Hwnd)
        Assert(autoToggle.GetValue() = 0, "native toggle click updates state")
        autoToggle.SetValue(1)
        winEditor := settingsWindow._Panels["hotkeys"].Main
        winEditor.SetValue("#^+X")
        Assert(UI_NormalizeHotkey(winEditor.GetValue()) = UI_NormalizeHotkey("#^+X"), "Win modifier set")
        SendMessage(0xF5,0,0,winEditor.WinCtrl.Hwnd)
        Assert(UI_NormalizeHotkey(winEditor.GetValue()) = UI_NormalizeHotkey("^+X"), "native Win chip click clears modifier")
        winEditor.SetValue("^+X")
        settingsWindow._TabBar._SelectTab("main")
        Assert(settingsWindow._Panels["main"].Visible, "main tab selection")
        for ctrl in settingsWindow._Panels["hotkeys"].NativeControls
            Assert(!ctrl.Visible, "inactive control leaked")
        UI_SettingsFilter(settingsWindow, "звук")
        Assert(settingsWindow._CurrentTab = "main", "search matching tab")
        UI_SettingsFilter(settingsWindow, "zzzz-no-match")
        Assert(settingsWindow.NoResults.Visible, "empty search results")
        UI_SettingsFilter(settingsWindow, "")
        Assert(settingsWindow._Panels["main"].Visible, "clear search")
        mainPanel := settingsWindow._Panels["main"]
        hotkeysPanel := settingsWindow._Panels["hotkeys"]
        mainPanel.Auto.SetValue(0)
        mainPanel.Sound.SetValue(1)
        mainPanel.Restore.SetValue(1)
        mainPanel.Layout.SetValue(1)
        mainPanel.Duration.SetValue(4200)
        mainPanel.CopyKey.SetValue("^Insert")
        hotkeysPanel.Main.SetValue("^!F11")
        hotkeysPanel.Copy.SetValue("^!F12")
        settingsWindow._Panels["appearance"].Theme.Choose(3)
        settingsWindow._Panels["appearance"].Glass.SetValue(0)
        Assert(UI_SaveSettingsFromUI(settingsWindow, settingsWindow._Panels), "save valid settings")
        Assert(IniRead(cfg.iniPath, "Main", "CopyKey") = "^Insert", "copy key persisted")
        Assert(IniRead(cfg.iniPath, "Main", "TooltipMs") = "4200", "duration persisted")
        Assert(cfg.sound = 1 && cfg.restore = 1 && cfg.autoPaste = 0 && cfg.switchLayout = 1, "toggles applied")
        Assert(cfg.hotkey = "^!F11" && cfg.hotkeyCopy = "^!F12", "hotkeys applied")
        Assert(IniRead(cfg.iniPath,"Appearance","Theme") = "dark", "theme persisted")
        Assert(IniRead(cfg.iniPath,"Appearance","Material") = "solid", "material persisted")
        settingsWindow := UI_ShowSettings()
        Assert(DesignTokens.IsDarkMode && !settingsWindow.BackdropEnabled, "solid dark theme applied")
        Assert(settingsWindow._Panels["main"].CopyKey.GetValue() = "^Insert", "reopen settings")
        before := FileRead(cfg.iniPath)
        settingsWindow._Panels["hotkeys"].Copy.SetValue("^!F11")
        Assert(!UI_SaveSettingsFromUI(settingsWindow, settingsWindow._Panels), "duplicate hotkeys rejected")
        Assert(FileRead(cfg.iniPath) = before, "invalid save left file untouched")
        settingsWindow._Panels["hotkeys"].Main.SetValue("")
        Assert(!UI_SaveSettingsFromUI(settingsWindow, settingsWindow._Panels), "empty hotkey rejected")
        UI_ResetSettings(settingsWindow)
        Assert(settingsWindow._Panels["main"].Duration.GetValue() = 2500, "reset form")
        Assert(FileRead(cfg.iniPath) = before, "reset not saved implicitly")
        settingsWindow.Destroy()
        ToastManager.DismissAll()
        ToastManager.Show("Проверка уведомления", {Duration: 100})
        Sleep(300)
        Assert(ToastManager.Toasts.Length = 0, "toast expiration")
        Loop 7
            ToastManager.Show("Уведомление " A_Index, {Duration: 0})
        Assert(ToastManager.Toasts.Length = 5, "toast limit")
        ToastManager.DismissAll()
        Assert(ToastManager.Toasts.Length = 0, "toast cleanup")
        Assert(GlassPaint.Items.Count = 0 && GlassPaint.Toggles.Count = 0 && GlassPaint.Windows.Count = 0, "paint bindings released")
        report("PASS: " pairs " map pairs; About, tabs, search, settings persistence, validation, reset, toasts.")
        ExitApp(0)
    } catch as err {
        report("FAIL: " err.File ":" err.Line " " err.Message)
        ExitApp(1)
    }
}

Persistent
A_TrayMenu.Delete()
A_TrayMenu.Add("О программе (тест)", (*) => UI_ShowAbout())
A_TrayMenu.Add("Настройки (тест)", (*) => UI_ShowSettings())
A_TrayMenu.Add("Уведомление (тест)", (*) => ToastManager.Show("Тестовое уведомление без изменения пользовательских настроек."))
A_TrayMenu.Add("Выход", (*) => ExitApp())
if A_Args.Length && A_Args[1] = "--settings"
    UI_ShowSettings()
else
    UI_ShowAbout()
