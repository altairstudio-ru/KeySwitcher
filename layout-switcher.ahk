; ============================================================
;  layout-switcher.ahk  —  AltaiR Key Switcher
;  Исправляет текст, набранный не в той раскладке (RU<->EN).
;  Запуск: глобальный хоткей / ПКМ в Explorer / иконка в трее.
;  Требует: AutoHotkey v2.
; ============================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

#Include "layout-map.ahk"

A_IconTip := "AltaiR Key Switcher"

; ------------------------- Конфигурация -------------------------
cfg := { }
cfg.iniPath := A_ScriptDir "\config.ini"

cfg.hotkey     := IniRead(cfg.iniPath, "Hotkeys", "Hotkey", "^+X")
cfg.hotkeyCopy := IniRead(cfg.iniPath, "Hotkeys", "HotkeyCopyOnly", "^!+X")
cfg.direction  := IniRead(cfg.iniPath, "Main", "Direction", "auto")
cfg.autoPaste  := Integer(IniRead(cfg.iniPath, "Main", "AutoPaste", "1"))
cfg.sound      := Integer(IniRead(cfg.iniPath, "Main", "Sound", "0"))
cfg.restore    := Integer(IniRead(cfg.iniPath, "Main", "RestoreClipboard", "0"))
cfg.tooltipMs  := Integer(IniRead(cfg.iniPath, "Main", "TooltipMs", "2500"))
cfg.copyKey    := IniRead(cfg.iniPath, "Main", "CopyKey", "^c")
cfg.switchLayout := Integer(IniRead(cfg.iniPath, "Main", "SwitchLayout", "0"))

; ------------------- Режимы запуска (ПКМ/тесты) -------------------
if A_Args.Length > 0 {
    arg := A_Args[1]
    if arg = "--convert-clipboard" {
        ConvertClipboardStandalone()
        ExitApp()
    }
    if arg = "--convert-filename" {
        if A_Args.Length < 2 {
            MsgBox("Не передан путь к файлу.", "AltaiR Key Switcher")
            ExitApp()
        }
        RenameEntry(A_Args[2])
        ExitApp()
    }
    if arg = "--selftest" {
        pairs := 0, fail := 0
        SelfTest(&pairs, &fail)
        MsgBox("Самопроверка карты раскладок`nПар в карте: " pairs "`nОшибок: " fail, "AltaiR Key Switcher")
        ExitApp()
    }
}

; ------------------------- Горячие клавиши -------------------------
if cfg.hotkey != ''
    Hotkey(cfg.hotkey, (*) => RunConvert(false))
if cfg.hotkeyCopy != ''
    Hotkey(cfg.hotkeyCopy, (*) => RunConvert(true))

; ---------------- Трей-меню ----------------------------------------
tray := A_TrayMenu
tray.Delete()
tray.Add("AltaiR Key Switcher (из буфера)", (*) => ConvertClipboardStandalone())
tray.Add()
tray.Add("Настройки", (*) => UI_ShowSettings())
tray.Add("О программе", (*) => UI_ShowAbout())
tray.Add("Выход", (*) => ExitApp())

; ============================================================
;  RunConvert(copyOnly) — основной сценарий «выделил -> исправил»
;   1. временно очищает буфер, имитирует CopyKey (Ctrl+C)
;   2. ждёт появления текста (до 1.5 c)
;   3. определяет направление и конвертирует
;   4. кладёт результат в буфер
;   5. при autopaste=1 (и не copyOnly) вставляет в то же окно
; ============================================================
global busy := 0

RunConvert(copyOnly := false) {
    global cfg, busy
    if busy
        return
    busy := 1
    try {
        saved := A_Clipboard
        activeHwnd := WinGetID("A")

        A_Clipboard := ""
        SendInput(cfg.copyKey)

        ; ждём, пока приложение положит выделение в буфер
        t := 0
        while (A_Clipboard = "" && t < 1500) {
            Sleep(10)
            t += 10
        }

        raw := A_Clipboard
        if raw = "" {
            A_Clipboard := saved
            ShowToast("Нет текста для преобразования.`nВыделите текст и нажмите снова.")
            return
        }

        dir := DetectDirection(raw)
        if dir = 'none' || dir = 'ambig' {
            A_Clipboard := saved
            if dir = 'none'
                ShowToast("Нет текста для преобразования.")
            else
                ShowToast("Не удалось определить направление раскладки.`nТекст оставлен без изменений.")
            return
        }

        converted := ConvertLayout(raw, dir)
        A_Clipboard := converted
        ApplyLayoutSwitch(dir)
        if cfg.sound
            SoundBeep(880, 90)

        ; автовставка — только если фокус не сменился
        if !copyOnly && cfg.autoPaste && WinGetID("A") = activeHwnd
            SendInput("^v")
        else if cfg.restore
            A_Clipboard := saved

        ShowToast(MakePreview(raw, converted) "`nОтмена: Ctrl+Z")
    } finally {
        busy := 0
    }
}

; ============================================================
;  ConvertClipboardStandalone() — по ПКМ/трею:
;  конвертирует уже имеющееся содержимое буфера обмена.
; ============================================================
ConvertClipboardStandalone() {
    raw := A_Clipboard
    if raw = "" {
        MsgBox("Буфер обмена пуст.`nСначала скопируйте текст.", "AltaiR Key Switcher")
        return
    }
    dir := DetectDirection(raw)
    if dir = 'none' || dir = 'ambig' {
        MsgBox(
            dir = 'none'
                ? "Буфер обмена не содержит текста для преобразования."
                : "Не удалось определить направление раскладки.",
            "AltaiR Key Switcher")
        return
    }
    converted := ConvertLayout(raw, dir)
    A_Clipboard := converted
    ApplyLayoutSwitch(dir)
    MsgBox(MakePreview(raw, converted) "`n`nСкопировано в буфер обмена.", "AltaiR Key Switcher")
}

; ============================================================
;  ApplyLayoutSwitch(dir) — опция SwitchLayout:
;  вместе с текстом переключает и язык ввода активного окна.
;  dir="RU" -> раскладка 0419 (русская),
;  dir="EN" -> раскладка 0409 (английская/US).
; ============================================================
ApplyLayoutSwitch(dir) {
    global cfg
    if !cfg.switchLayout
        return
    klid := dir = 'RU' ? "00000419" : "00000409"
    hkl := DllCall("LoadKeyboardLayout", "Str", klid, "UInt", 0x1, "Ptr")
    if hkl
        SendMessage(0x0050, 0, hkl, , "A")   ; WM_INPUTLANGCHANGEREQUEST
}

; ============================================================
;  RenameEntry(path) — по ПКМ на файле/папке:
;  конвертирует имя (без расширения) и переименовывает объект.
; ============================================================
RenameEntry(path) {
    if !FileExist(path) && !DirExist(path) {
        MsgBox("Путь не найден:`n" path, "AltaiR Key Switcher")
        return
    }

    SplitPath(path, &name, &dir)
    isDir := DirExist(path) != ""

    base := name
    ext  := ""
    if !isDir {
        dot := InStr(name, ".", 0, -1)   ; последняя точка
        if dot > 1 {
            base := SubStr(name, 1, dot - 1)
            ext  := SubStr(name, dot)
        }
    }

    dir2 := DetectDirection(base)
    if dir2 = 'none' || dir2 = 'ambig' {
        MsgBox("В имени нет данных для переключения раскладки.", "AltaiR Key Switcher")
        return
    }

    newName := ConvertLayout(base, dir2) . ext
    if newName = name {
        MsgBox("Имя не изменилось:", "AltaiR Key Switcher")
        return
    }

    ; Недопустимые в именах Windows символы (< > : " / \ | ? * и упр.)
    ; появляются при конвертации (@ -> ", ^ -> :, & -> ? и т.п.)
    if RegExMatch(newName, "[<>:`"/\\|?*\x00-\x1F]") {
        MsgBox(
            "В исправленном имени есть недопустимые символы:`n"
            newName
            "`n`nWindows не разрешает в именах файлов: < > : "
            "`" / \ | ? *"
            "`n`nПереименуйте такой файл вручную.",
            "AltaiR Key Switcher"
        )
        return
    }

    newPath := dir "\" newName
    if FileExist(newPath) || DirExist(newPath) {
        MsgBox("Объект с таким именем уже существует:`n" newPath, "AltaiR Key Switcher")
        return
    }

    try {
        if isDir
            DirMove(path, newPath)
        else
            FileMove(path, newPath)
    } catch {
        MsgBox("Не удалось переименовать:`n" name, "AltaiR Key Switcher")
        return
    }

    MsgBox("Переименовано:`n" name " → " newName, "AltaiR Key Switcher")
}

; ------------------------- Вспомогательные -------------------------
MakePreview(raw, converted) {
    if StrLen(raw) <= 40
        return raw " → " converted
    return SubStr(raw, 1, 20) "… → " SubStr(converted, 1, 20) "…"
}

ShowToast(msg, ms := 0) {
    global cfg
    if ms = 0
        ms := cfg.tooltipMs
    CoordMode("Mouse", "Screen")
    CoordMode("ToolTip", "Screen")
    MouseGetPos(&cursorX, &cursorY)
    ToolTip(msg, cursorX + 24, cursorY + 24)
    SetTimer(() => ToolTip(), -ms)
}

; UI-модуль подключается в конце, чтобы функции главного скрипта
; (RunConvert, ShowToast) были видны статическому анализатору.
#include "src\ui.ahk"