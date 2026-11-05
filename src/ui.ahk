#Requires AutoHotkey v2.0
#Include "ui\tokens.ahk"
#Include "ui\core.ahk"
#Include "ui\components.ahk"

APP_NAME := "AltaiR Key Switcher"
APP_VERSION := "2.0.1"

UI_HotkeyToDisplay(hk) {
    out := ""
    while RegExMatch(hk, "^[\^+!#]") {
        modifier := SubStr(hk, 1, 1)
        out .= Map("^", "Ctrl", "+", "Shift", "!", "Alt", "#", "Win")[modifier] " + "
        hk := SubStr(hk, 2)
    }
    return out StrUpper(hk)
}

UI_ShowAbout() {
    global cfg
    DesignTokens.DetectSystemTheme()
    win := GlassWindow("О программе — " APP_NAME)
    margin := DesignTokens.Space(6)
    contentW := 552
    fg := DesignTokens.GetTextColor("fg-primary", DesignTokens.IsDarkMode)
    muted := DesignTokens.GetTextColor("fg-secondary", DesignTokens.IsDarkMode)
    accent := DesignTokens.GetTextColor("accent", DesignTokens.IsDarkMode)
    logoSize := DesignTokens.Sizing["logo-size"]
    imgPath := A_ScriptDir "\icon.png"
    if FileExist(imgPath)
        win.AddPicture("x24 y28 w" logoSize " h" logoSize, imgPath)
    win.SetFont("s22 bold", "Segoe UI")
    win.AddText("x96 y26 w480 h36 c" fg, APP_NAME)
    win.SetFont("s11 norm", "Segoe UI")
    win.AddText("x96 y66 w460 h24 c" muted, "Версия " APP_VERSION " · RU ↔ EN")

    y := 112
    descCard := GlassCard(win, {x: margin, y: y, w: contentW, h: 108})
    descCard.SetFont("s12 norm", "Segoe UI")
    descCard.AddText("x16 y16 w520 h80 BackgroundTrans c" muted,
        "Исправляет текст, набранный не в той раскладке (RU ↔ EN).`n"
        "Выделите текст и нажмите горячую клавишу — выделение будет заменено исправленным текстом.")
    y += 132
    win.SetFont("s15 bold", "Segoe UI")
    win.AddText("x24 y" y " w552 h28 c" fg, "Горячие клавиши")
    y += 40
    cardWidth := 270
    hk1 := GlassCard(win, {x: margin, y: y, w: cardWidth, h: 96})
    hk1.SetFont("s11 norm", "Segoe UI")
    hk1.AddText("x16 y12 w238 h24 BackgroundTrans c" fg, "Исправить и вставить")
    hk1.SetFont("s12 bold", "Segoe UI")
    hk1.AddText("x16 y46 w238 h30 BackgroundTrans c" accent, UI_HotkeyToDisplay(cfg.hotkey))
    hk2 := GlassCard(win, {x: margin + cardWidth + 12, y: y, w: cardWidth, h: 96})
    hk2.SetFont("s11 norm", "Segoe UI")
    hk2.AddText("x16 y12 w238 h24 BackgroundTrans c" fg, "Только скопировать")
    hk2.SetFont("s12 bold", "Segoe UI")
    hk2.AddText("x16 y46 w238 h30 BackgroundTrans c" accent, UI_HotkeyToDisplay(cfg.hotkeyCopy))
    y += 112
    win.SetFont("s10 norm", "Segoe UI")
    win.AddText("x24 y" y " w552 h24 c" muted, "Отмена замены: Ctrl + Z в приложении, где вы исправляли текст.")
    y += 36
    Divider(win, {x: margin, y: y, w: contentW})
    y += 16
    ConfigPathDisplay(win, cfg.iniPath, {x: margin, y: y, w: contentW})
    y += 44
    openSettings(*) {
        win.Destroy()
        UI_ShowSettings()
    }
    win.SetFont("s11 norm", "Segoe UI")
    FooterActions(win, openSettings, (*) => win.Destroy(), {
        x: margin, y: y, w: contentW, SaveText: "Настройки", CancelText: "Закрыть"
    })
    y += 60
    win.SetFont("s10 norm", "Segoe UI")
    win.AddText("x24 y" y " w552 h22 Center c" muted, "AltaiR Key Switcher v" APP_VERSION " · исправление раскладки RU ↔ EN")
    win.Show("w600 h" (y + 42))
    return win
}

UI_ShowSettings() {
    global cfg
    DesignTokens.DetectSystemTheme()
    win := GlassWindow("Настройки — " APP_NAME)
    margin := DesignTokens.Space(6)
    contentW := 552
    fg := DesignTokens.GetTextColor("fg-primary", DesignTokens.IsDarkMode)
    win.SetFont("s18 bold", "Segoe UI")
    win.AddText("x24 y20 w552 h34 c" fg, "Настройки")
    win.SetFont("s11 norm", "Segoe UI")
    win.Search := SearchBox(win, "Поиск настроек… (Ctrl + F)", {
        x: margin, y: 64, w: contentW, h: 34,
        OnSearch: (query) => UI_SettingsFilter(win, query)
    })
    win.BindShortcut("^f", (*) => win.Search.Control.Focus())
    tabs := [
        {id: "hotkeys", label: "Горячие клавиши", icon: Icons.Keyboard},
        {id: "main", label: "Основные", icon: Icons.Settings},
        {id: "advanced", label: "Дополнительно", icon: Icons.Info}
    ]
    navigation := TabBar(win, tabs, {
        x: margin, y: 112, w: contentW, Selected: "hotkeys",
        OnChange: (id) => UI_SettingsSwitchTab(win, id)
    })
    win._TabBar := navigation
    panels := Map()
    ini := cfg.iniPath
    panels["hotkeys"] := UI_BuildPanel(win, UI_CreateHotkeysTab, margin, 164, contentW,
        IniRead(ini, "Hotkeys", "Hotkey", "^+X"), IniRead(ini, "Hotkeys", "HotkeyCopyOnly", "^!+X"))
    panels["main"] := UI_BuildPanel(win, UI_CreateMainTab, margin, 164, contentW,
        Integer(IniRead(ini, "Main", "AutoPaste", "1")), Integer(IniRead(ini, "Main", "Sound", "0")),
        Integer(IniRead(ini, "Main", "RestoreClipboard", "0")), Integer(IniRead(ini, "Main", "TooltipMs", "2500")),
        IniRead(ini, "Main", "CopyKey", "^c"), Integer(IniRead(ini, "Main", "SwitchLayout", "0")))
    panels["advanced"] := UI_BuildPanel(win, UI_CreateAdvancedTab, margin, 164, contentW)
    win._Panels := panels
    win._CurrentTab := "hotkeys"
    for id, panel in panels
        UI_SetPanelVisible(panel, id = "hotkeys")
    win.SetFont("s12 norm", "Segoe UI")
    win.NoResults := win.AddText("x24 y200 w552 h50 Hidden c" fg, "По этому запросу ничего не найдено.")
    win.SetFont("s10 norm", "Segoe UI")
    win.Status := win.AddText("x24 y540 w552 h44 c" DesignTokens.GetTextColor("accent", DesignTokens.IsDarkMode), "")
    win.SetFont("s11 norm", "Segoe UI")
    win.Footer := FooterActions(win, (*) => UI_SaveSettingsFromUI(win, panels), (*) => win.Destroy(),
        {x: margin, y: 590, w: contentW})
    win.Show("w600 h654")
    return win
}

UI_BuildPanel(win, builder, args*) {
    existing := Map()
    for ctrl in win.Gui
        existing[ctrl.Hwnd] := true
    panel := builder(win, args*)
    panel.NativeControls := []
    for ctrl in win.Gui {
        if !existing.Has(ctrl.Hwnd)
            panel.NativeControls.Push(ctrl)
    }
    return panel
}

UI_CreateHotkeysTab(win, x, y, w, hk, hkCopy) {
    panel := {Controls: [], SearchText: "горячие клавиши хоткей выделение вставить скопировать буфер ctrl shift alt win"}
    SectionHeader(win, "Горячие клавиши", {x: x, y: y, w: w})
    y += 42
    panel.Main := HotkeyEditor(win, "Исправить выделение и вставить", hk, {x: x, y: y, w: w, name: "hk_main"})
    panel.Controls.Push(panel.Main)
    y += 94
    panel.Copy := HotkeyEditor(win, "Исправить выделение и только скопировать", hkCopy, {x: x, y: y, w: w, name: "hk_copy"})
    panel.Controls.Push(panel.Copy)
    y += 100
    win.SetFont("s11 norm", "Segoe UI")
    win.AddText("x" x " y" y " w" w " h60 c" DesignTokens.GetTextColor("fg-secondary", DesignTokens.IsDarkMode),
        "Задайте сочетание клавиш в поле. Изменения применятся после нажатия «Сохранить».")
    return panel
}

UI_CreateMainTab(win, x, y, w, autoPaste, sound, restore, ms, copyKey, switchLayout) {
    panel := {Controls: [], SearchText: "основные параметры звук sound autopaste вставка буфер restoreclipboard раскладка switchlayout подсказка время tooltipms копировать copykey"}
    SectionHeader(win, "Основные параметры", {x: x, y: y, w: w})
    y += 40
    win.SetFont("s11 norm", "Segoe UI")
    panel.Auto := ToggleSwitch(win, "Сразу заменять выделение исправленным текстом", {x: x, y: y, w: w, Value: autoPaste})
    panel.Sound := ToggleSwitch(win, "Звуковой сигнал при исправлении", {x: x, y: y + 40, w: w, Value: sound})
    panel.Restore := ToggleSwitch(win, "Восстанавливать прежнее содержимое буфера", {x: x, y: y + 80, w: w, Value: restore})
    panel.Layout := ToggleSwitch(win, "Менять язык ввода вслед за исправленным текстом", {x: x, y: y + 120, w: w, Value: switchLayout})
    panel.Controls.Push(panel.Auto, panel.Sound, panel.Restore, panel.Layout)
    y += 170
    panel.Duration := Slider(win, "Время показа подсказки, мс", 50, 30000, ms, {x: x, y: y, w: w - 80, name: "slider_ms"})
    y += 78
    panel.CopyKey := HotkeyEditor(win, "Клавиша копирования выделения", StrReplace(StrReplace(copyKey, "{"), "}"), {x: x, y: y, w: w, name: "hk_copykey"})
    panel.Controls.Push(panel.Duration, panel.CopyKey)
    return panel
}

UI_CreateAdvancedTab(win, x, y, w) {
    panel := {Controls: [], SearchText: "дополнительно сброс настройки умолчанию конфигурация config файл"}
    SectionHeader(win, "Дополнительно", {x: x, y: y, w: w})
    y += 48
    win.SetFont("s11 norm", "Segoe UI")
    win.AddText("x" x " y" y " w" w " h70 c" DesignTokens.GetTextColor("fg-secondary", DesignTokens.IsDarkMode),
        "Сброс восстановит стандартные горячие клавиши и параметры в этом окне. Чтобы применить их, нажмите «Сохранить».")
    y += 94
    panel.Controls.Push(SecondaryButton(win, "Сбросить настройки", {x: x, y: y, w: 220, h: 40, OnClick: (*) => UI_ResetSettings(win)}))
    return panel
}

UI_SetPanelVisible(panel, visible) {
    panel.Visible := visible
    for ctrl in panel.NativeControls
        ctrl.Visible := visible
}

UI_SettingsSwitchTab(win, tabId) {
    win._CurrentTab := tabId
    win.NoResults.Visible := false
    for id, panel in win._Panels
        UI_SetPanelVisible(panel, id = tabId)
}

UI_SettingsFilter(win, query) {
    if !win.HasOwnProp("_Panels")
        return
    query := StrLower(Trim(query))
    if query = "" {
        UI_SettingsSwitchTab(win, win._CurrentTab)
        return
    }
    for id, panel in win._Panels {
        if InStr(panel.SearchText, query) {
            if win._TabBar.Selected != id
                win._TabBar._SelectTab(id)
            else
                UI_SettingsSwitchTab(win, id)
            return
        }
    }
    for id, panel in win._Panels
        UI_SetPanelVisible(panel, false)
    win.NoResults.Visible := true
}

UI_SaveSettingsFromUI(win, panels) {
    hotkeys := panels["hotkeys"]
    main := panels["main"]
    values := {
        hotkey: hotkeys.Main.GetValue(), hotkeyCopy: hotkeys.Copy.GetValue(),
        autoPaste: main.Auto.GetValue(), sound: main.Sound.GetValue(), restore: main.Restore.GetValue(),
        switchLayout: main.Layout.GetValue(), tooltipMs: main.Duration.GetValue(), copyKey: main.CopyKey.GetValue()
    }
    problem := UI_ApplySettings(values)
    if problem != "" {
        win.Status.Text := problem
        return false
    }
    win.Destroy()
    ToastManager.Show("Настройки сохранены.")
    return true
}

UI_ValidateSettings(values) {
    for name in ["hotkey", "hotkeyCopy", "copyKey"] {
        hk := values.%name%
        if !RegExMatch(hk, "^[\^!+#]*[^\s{}]+$")
            return "Укажите корректные сочетания клавиш во всех полях."
        key := RegExReplace(hk, "^[\^!+#]*")
        if !GetKeyVK(key) && !GetKeySC(key)
            return "Неизвестная клавиша: " key
    }
    if StrLower(UI_NormalizeHotkey(values.hotkey)) = StrLower(UI_NormalizeHotkey(values.hotkeyCopy))
        return "Основной хоткей и хоткей копирования должны различаться."
    if !IsInteger(values.tooltipMs) || values.tooltipMs < 50 || values.tooltipMs > 30000
        return "Время подсказки: целое число от 50 до 30000 мс."
    return ""
}

UI_NormalizeHotkey(hk) {
    modifiers := RegExReplace(hk, "[^\^!+#].*$")
    result := ""
    for modifier in ["^", "!", "+", "#"] {
        if InStr(modifiers, modifier)
            result .= modifier
    }
    key := RegExReplace(hk, "^[\^!+#]*")
    return result Format("vk{:X}sc{:X}", GetKeyVK(key), GetKeySC(key))
}

UI_HotkeyToSend(hk) {
    if InStr(hk, "{")
        return hk
    RegExMatch(hk, "^([\^!+#]*)(.+)$", &parts)
    return parts[1] "{" parts[2] "}"
}

UI_ApplySettings(values) {
    global cfg
    problem := UI_ValidateSettings(values)
    if problem != ""
        return problem
    oldMain := cfg.hotkey
    oldCopy := cfg.hotkeyCopy
    stagedIni := cfg.iniPath "." DllCall("GetCurrentProcessId") ".tmp"
    try {
        if FileExist(cfg.iniPath)
            FileCopy(cfg.iniPath, stagedIni, true)
        IniWrite(values.hotkey, stagedIni, "Hotkeys", "Hotkey")
        IniWrite(values.hotkeyCopy, stagedIni, "Hotkeys", "HotkeyCopyOnly")
        for field, key in Map("autoPaste", "AutoPaste", "sound", "Sound", "restore", "RestoreClipboard",
            "switchLayout", "SwitchLayout", "tooltipMs", "TooltipMs", "copyKey", "CopyKey")
            IniWrite(values.%field%, stagedIni, "Main", key)
        if oldMain != ""
            Hotkey(oldMain, "Off")
        if oldCopy != ""
            Hotkey(oldCopy, "Off")
        Hotkey(values.hotkey, (*) => RunConvert(false), "On")
        Hotkey(values.hotkeyCopy, (*) => RunConvert(true), "On")
        FileMove(stagedIni, cfg.iniPath, true)
    } catch as err {
        try Hotkey(values.hotkey, "Off")
        try Hotkey(values.hotkeyCopy, "Off")
        if oldMain != ""
            Hotkey(oldMain, (*) => RunConvert(false), "On")
        if oldCopy != ""
            Hotkey(oldCopy, (*) => RunConvert(true), "On")
        return "Не удалось применить настройки: " err.Message
    } finally {
        if FileExist(stagedIni)
            FileDelete(stagedIni)
    }
    for field, value in values.OwnProps()
        cfg.%field% := value
    return ""
}

UI_ResetSettings(win) {
    hotkeys := win._Panels["hotkeys"]
    main := win._Panels["main"]
    hotkeys.Main.SetValue("^+X")
    hotkeys.Copy.SetValue("^!+X")
    main.Auto.SetValue(1)
    main.Sound.SetValue(0)
    main.Restore.SetValue(0)
    main.Layout.SetValue(0)
    main.Duration.SetValue(2500)
    main.CopyKey.SetValue("^c")
    win.Status.Text := "Значения по умолчанию восстановлены. Нажмите «Сохранить», чтобы применить."
}

ShowToast(msg, ms := 0) {
    global cfg
    ToastManager.Show(msg, {Duration: ms = 0 ? cfg.tooltipMs : ms})
}
