; ============================================================
;  ui.ahk  —  GUI-модуль «AltaiR Key Switcher»
;  Окно «О программе» и окно «Настройки» (config.ini).
;
;  Подключается основным скриптом:  #Include "src\ui.ahk"
;  Экспортируемые функции:
;    UI_ShowAbout()     — окно «О программе»
;    UI_ShowSettings()  — окно «Настройки»
;
;  Модуль расширяет интерфейс, но не трогает логику
;  RunConvert / ConvertClipboardStandalone / RenameEntry.
; ============================================================

APP_NAME    := "AltaiR Key Switcher"
APP_VERSION := "1.1.0"

; ---------------- Палитра и шрифты ----------------
CLR_BG      := "F5F7FB"   ; фон окна
CLR_CARD    := "FFFFFF"   ; карточка
CLR_BORDER  := "D8DFEA"   ; рамка карточки
CLR_ACCENT  := "2E5BE0"   ; акцентный синий
CLR_TEXT    := "1C2438"   ; основной текст
CLR_MUTED   := "5A6B8C"   ; приглушённый текст
CLR_DIVIDER := "B9C6E4"   ; тонкая линия-разделитель

FONT_FAMILY := "Segoe UI"

; ============================================================
;  UI_HotkeyToDisplay(hk)
;  Приводит формат AHK (^+X) к читаемому виду (Ctrl+Shift+X).
; ============================================================
UI_HotkeyToDisplay(hk) {
    out := ""
    for ch in StrSplit(hk) {
        if ch = '^'
            out .= "Ctrl+"
        else if ch = '+'
            out .= "Shift+"
        else if ch = '!'
            out .= "Alt+"
        else if ch = '#'
            out .= "Win+"
        else
            out .= ch
    }
    return out
}

; ============================================================
;  UI_ShowAbout() — окно «О программе»
; ============================================================
UI_ShowAbout() {
    global cfg
    g := Gui("+AlwaysOnTop +OwnDialogs", "О программе — " APP_NAME)
    g.BackColor := CLR_BG
    g.SetFont("s10", FONT_FAMILY)

    ; ---------- Шапка: логотип + название ----------
    imgPath := A_ScriptDir "\icon.png"
    logo := ""
    if FileExist(imgPath) {
        try
            logo := g.AddPicture("x24 y24 w96 h96", imgPath)
    }
    if !logo {
        g.SetFont("s36", FONT_FAMILY)
        logo := g.AddText("x24 y24 w96 h96 Center c" CLR_ACCENT, "п⇄p")
        g.SetFont("s10", FONT_FAMILY)
    }

    g.SetFont("s20 bold")
    g.AddText("x140 y26 w310 h34 c" CLR_TEXT, APP_NAME)

    g.SetFont("s9", FONT_FAMILY)
    g.AddText("x140 y62 w310 h18 c" CLR_MUTED, "Версия " APP_VERSION " · RU ↔ EN")

    g.SetFont("s10", FONT_FAMILY)
    g.AddText("x140 y84 w310 h36 c" CLR_TEXT, "Один клик — и текст, набранный не в той"
        . " раскладке, снова читается в нужной.")

    ; ---------- Разделитель ----------
    g.AddProgress("x24 y136 w412 h2 c" CLR_DIVIDER " Background" CLR_BG, 100)

    ; ---------- Карточка-описание ----------
    g.SetFont("s10", FONT_FAMILY)
    g.AddText("x24 y148 w412 h74 Background" CLR_CARD " Border c" CLR_TEXT,
        "   Исправляет текст, набранный не в той раскладке (RU ↔ EN):"
        . "`n   выделите текст и нажмите горячую клавишу —"
        . "`n   выделение будет заменено исправленным текстом.")

    ; ---------- Горячие клавиши ----------
    g.AddGroupBox("x24 y236 w412 h120 Section", "Горячие клавиши")
    g.SetFont("s10", FONT_FAMILY)
    g.AddText("x40 ys+16 w220 h22 c" CLR_TEXT, "Конвертировать и вставить")
    g.SetFont("s10 bold", FONT_FAMILY)
    g.AddText("x276 ys+16 w140 h22 Right c" CLR_ACCENT, UI_HotkeyToDisplay(cfg.hotkey))
    g.SetFont("s10", FONT_FAMILY)
    g.AddText("x40 ys+44 w220 h22 c" CLR_TEXT, "Только скопировать")
    g.SetFont("s10 bold", FONT_FAMILY)
    g.AddText("x276 ys+44 w140 h22 Right c" CLR_ACCENT, UI_HotkeyToDisplay(cfg.hotkeyCopy))
    g.SetFont("s8.5", FONT_FAMILY)
    g.AddText("x40 ys+72 w370 h18 c" CLR_MUTED, "Формат: ^ — Ctrl,  + — Shift,  ! — Alt (как в config.ini)")

    ; ---------- Файлы ----------
    g.AddGroupBox("x24 y368 w412 h74 Section", "Файлы")
    g.SetFont("s10", FONT_FAMILY)
    g.AddText("x40 ys+16 w372 h20 c" CLR_TEXT, "Расположение конфигурации:")
    g.SetFont("s9", FONT_FAMILY)
    g.AddText("x40 ys+38 w372 h22 c" CLR_MUTED, cfg.iniPath)

    ; ---------- Кнопки ----------
    btnSettings := g.AddButton("x24 y458 w120 h30", "Настройки…")
    btnSettings.OnEvent("Click", (*) => UI_CloseAboutOpenSettings(g))
    btnClose := g.AddButton("x326 y458 w110 h30 Default", "Закрыть")
    btnClose.OnEvent("Click", (*) => g.Destroy())

    ; ---------- Футер ----------
    g.SetFont("s8.5", FONT_FAMILY)
    g.AddText("x24 y496 w412 h20 Center c" CLR_MUTED,
        "AutoHotkey v" A_AhkVersion " · исправление раскладки RU ↔ EN")
    g.SetFont("s10", FONT_FAMILY)

    g.OnEvent("Close",  (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show("w460 h524")

    UI_CloseAboutOpenSettings(aboutGui) {
        aboutGui.Destroy()
        UI_ShowSettings()
    }
}

; ============================================================
;  UI_ShowSettings() — окно «Настройки» (редактор config.ini)
;  Читает ini при открытии, пишет при сохранении и применяет
;  значения сразу (без перезапуска), перерегистрируя хоткеи.
; ============================================================
UI_ShowSettings() {
    global cfg
    ini := cfg.iniPath

    cur_hk     := IniRead(ini, "Hotkeys", "Hotkey", "^+X")
    cur_hkCopy := IniRead(ini, "Hotkeys", "HotkeyCopyOnly", "^!+X")
    cur_auto   := Integer(IniRead(ini, "Main", "AutoPaste", "1"))
    cur_sound  := Integer(IniRead(ini, "Main", "Sound", "0"))
    cur_restore:= Integer(IniRead(ini, "Main", "RestoreClipboard", "0"))
    cur_ms     := Integer(IniRead(ini, "Main", "TooltipMs", "2500"))
    cur_copy   := IniRead(ini, "Main", "CopyKey", "^c")
    cur_layout := Integer(IniRead(ini, "Main", "SwitchLayout", "0"))

    g := Gui("+AlwaysOnTop +OwnDialogs", "Настройки — " APP_NAME)
    g.BackColor := CLR_BG
    g.SetFont("s10", FONT_FAMILY)

    ; ---------- Горячие клавиши ----------
    g.AddGroupBox("x24 y16 w412 h150 Section", "Горячие клавиши")
    g.AddText("x40 ys+22 w200 h22 c" CLR_TEXT, "Конвертировать и вставить")
    edHotkey := g.AddEdit("x240 ys+18 w170", cur_hk)
    g.AddText("x40 ys+52 w200 h22 c" CLR_TEXT, "Только скопировать")
    edHotkeyCopy := g.AddEdit("x240 ys+48 w170", cur_hkCopy)
    g.SetFont("s8.5", FONT_FAMILY)
    g.AddText("x40 ys+80 w372 h30 c" CLR_MUTED,
        "Формат AHK: ^ — Ctrl, + — Shift, ! — Alt, # — Win.`n"
        . "Пример: ^+X = Ctrl+Shift+X.")
    g.SetFont("s10", FONT_FAMILY)

    ; ---------- Основные параметры ----------
    g.AddGroupBox("x24 y178 w412 h248 Section", "Основные параметры")
    chkAuto := g.AddCheckbox("x40 ys+16 w372 h34", "Заменить выделение исправленным текстом сразу (AutoPaste)")
    chkAuto.Value := cur_auto
    chkSound := g.AddCheckbox("x40 ys+56 w372 h34", "Звуковой сигнал при срабатывании (Sound)")
    chkSound.Value := cur_sound
    chkRestore := g.AddCheckbox("x40 ys+96 w372 h34", "Возвращать прежнее содержимое буфера обмена (RestoreClipboard)")
    chkRestore.Value := cur_restore
    chkLayout := g.AddCheckbox("x40 ys+136 w372 h34", "Менять раскладку клавиатуры: исправил текст — сменил и язык ввода (SwitchLayout)")
    chkLayout.Value := cur_layout

    g.AddText("x40 ys+178 w210 h22 c" CLR_TEXT, "Время показа подсказки (TooltipMs), мс")
    edMs := g.AddEdit("x252 ys+174 w80", cur_ms)

    g.AddText("x40 ys+216 w210 h22 c" CLR_TEXT, "Клавиша «копировать» (CopyKey)")
    edCopy := g.AddEdit("x252 ys+212 w66", cur_copy)
    g.SetFont("s8.5", FONT_FAMILY)
    g.AddText("x322 ys+214 w96 h22 c" CLR_MUTED, "напр. ^c")
    g.SetFont("s10", FONT_FAMILY)

    ; ---------- Футер и кнопки ----------
    g.SetFont("s8.5", FONT_FAMILY)
    g.AddText("x24 y436 w412 h20 Center c" CLR_MUTED,
        "Изменения применяются сразу, без перезапуска программы.")
    g.SetFont("s10", FONT_FAMILY)

    btnCancel := g.AddButton("x332 y470 w104 h30", "Отмена")
    btnCancel.OnEvent("Click", (*) => g.Destroy())
    btnSave := g.AddButton("x224 y470 w104 h30 Default", "Сохранить")
    btnSave.OnEvent("Click",
        (*) => UI_SaveSettings(g, edHotkey, edHotkeyCopy, chkAuto, chkSound,
            chkRestore, chkLayout, edMs, edCopy))

    g.OnEvent("Close",  (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show("w460 h524")
}

; ============================================================
;  UI_SaveSettings(...) — валидация, запись в config.ini,
;  применение в памяти и перерегистрация хоткеев.
; ============================================================
UI_SaveSettings(g, edHotkey, edHotkeyCopy, chkAuto, chkSound, chkRestore, chkLayout, edMs, edCopy) {
    global cfg

    hk      := Trim(edHotkey.Text)
    hkCopy  := Trim(edHotkeyCopy.Text)
    copyKey := Trim(edCopy.Text)
    msText  := Trim(edMs.Text)

    ; ---------- Проверка значений ----------
    if hk = "" || !RegExMatch(hk, "^[0-9A-Za-z#!+^<>* ]+$") {
        MsgBox("Некорректный основной хоткей: «" hk "»`n"
            . "Формат AHK: ^ — Ctrl, + — Shift, ! — Alt, # — Win.", "Настройки")
        return
    }
    if hkCopy = "" || !RegExMatch(hkCopy, "^[0-9A-Za-z#!+^<>* ]+$") {
        MsgBox("Некорректный хоткей «только скопировать»: «" hkCopy "»`n"
            . "Формат AHK: ^ — Ctrl, + — Shift, ! — Alt, # — Win.", "Настройки")
        return
    }
    if copyKey = "" || !RegExMatch(copyKey, "^[0-9A-Za-z#!+^<>* ]+$") {
        MsgBox("Некорректная клавиша «копировать»: «" copyKey "»`n"
            . "По умолчанию: ^c (Ctrl+C).", "Настройки")
        return
    }
    try
        ms := Integer(msText)
    catch
        ms := 0
    if ms < 50 || ms > 30000 {
        MsgBox("TooltipMs: укажите целое число от 50 до 30000 мс.", "Настройки")
        return
    }

    ; ---------- Запись в config.ini ----------
    try {
        IniWrite(hk,      cfg.iniPath, "Hotkeys", "Hotkey")
        IniWrite(hkCopy,  cfg.iniPath, "Hotkeys", "HotkeyCopyOnly")
        IniWrite(chkAuto.Value ? 1 : 0,   cfg.iniPath, "Main", "AutoPaste")
        IniWrite(chkSound.Value ? 1 : 0,  cfg.iniPath, "Main", "Sound")
        IniWrite(chkRestore.Value ? 1 : 0,cfg.iniPath, "Main", "RestoreClipboard")
        IniWrite(chkLayout.Value ? 1 : 0, cfg.iniPath, "Main", "SwitchLayout")
        IniWrite(ms,      cfg.iniPath, "Main", "TooltipMs")
        IniWrite(copyKey, cfg.iniPath, "Main", "CopyKey")
    } catch {
        MsgBox("Не удалось записать настройки:`n" cfg.iniPath "`n`n"
            . "Проверьте права на запись в этот файл.", "Настройки")
        return
    }

    ; ---------- Применение в памяти (без перезапуска) ----------
    oldHk     := cfg.hotkey
    oldHkCopy := cfg.hotkeyCopy
    cfg.hotkey     := hk
    cfg.hotkeyCopy := hkCopy
    cfg.autoPaste  := chkAuto.Value ? 1 : 0
    cfg.sound      := chkSound.Value ? 1 : 0
    cfg.restore    := chkRestore.Value ? 1 : 0
    cfg.switchLayout := chkLayout.Value ? 1 : 0
    cfg.tooltipMs  := ms
    cfg.copyKey    := copyKey

    ; ---------- Перерегистрация хоткеев ----------
    if hk != oldHk {
        try
            Hotkey(oldHk, "Off")
        if hk != ""
            Hotkey(hk, (*) => RunConvert(false))
    }
    if hkCopy != oldHkCopy {
        try
            Hotkey(oldHkCopy, "Off")
        if hkCopy != ""
            Hotkey(hkCopy, (*) => RunConvert(true))
    }

    ShowToast("Настройки сохранены.")
    g.Destroy()
}