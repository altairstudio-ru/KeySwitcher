#Requires AutoHotkey v2.0
#Include "layout-switcher.ahk"

; End-to-end fixture: only our own edit field and known strings are used.
savedClipboard := ClipboardAll()
OnExit((*) => RestoreTestClipboard())
RestoreTestClipboard() {
    global savedClipboard
    A_Clipboard := savedClipboard
}

fixture := Gui(,"KeySwitcher conversion test")
field :=  fixture.AddEdit("w480 h80")
fixture.Show()
WinActivate("ahk_id " fixture.Hwnd)
WinWaitActive("ahk_id " fixture.Hwnd,,2)
cfg.copyKey := "^c"
cfg.autoPaste := 1
cfg.restore := 0
cfg.switchLayout := 0
cfg.sound := 0
cfg.tooltipMs := 10000
try {
    for sample in [["ghbdtn","привет"],["руддщ","hello"],["rfr ltkf","как дела"],["Привет","Ghbdtn"]] {
        ToastManager.DismissAll()
        WinActivate("ahk_id " fixture.Hwnd)
        WinWaitActive("ahk_id " fixture.Hwnd,,2)
        field.Value := sample[1]
        field.Focus()
        SendMessage(0xB1,0,-1,field.Hwnd)
        Sleep(50)
        A_Clipboard := "OLD CLIPBOARD CONTENT"
        RunConvert()
        Sleep(250)
        actual := field.Value
        FileAppend(sample[1] " -> " actual "`n","*","UTF-8")
        if actual != sample[2] {
            FileAppend("fixture clipboard=" A_Clipboard "; active=" (WinActive("ahk_id " fixture.Hwnd) ? 1 : 0) "; focus=" ControlGetFocus("ahk_id " fixture.Hwnd) "`n","*","UTF-8")
            if ToastManager.Toasts.Length
                FileAppend(ToastManager.Toasts[1].Message "`n","*","UTF-8")
            throw Error("Expected " sample[2] ", got " actual)
        }
    }
    cfg.restore := 1
    WinActivate("ahk_id " fixture.Hwnd)
    WinWaitActive("ahk_id " fixture.Hwnd,,2)
    field.Value := "ntcn"
    field.Focus()
    SendMessage(0xB1,0,-1,field.Hwnd)
    Sleep(50)
    A_Clipboard := "RESTORE SEED"
    RunConvert(true)
    if field.Value != "ntcn" || A_Clipboard != "тест"
        throw Error("Copy-only lost its result with RestoreClipboard enabled")
    field.Value := "ghbdtn"
    SendMessage(0xB1,0,-1,field.Hwnd)
    A_Clipboard := "RESTORE SEED"
    RunConvert()
    Sleep(250)
    if field.Value != "привет" || A_Clipboard != "RESTORE SEED"
        throw Error("Paste/restore scenario failed")
    field.Value := "no selection"
    SendMessage(0xB1,0,0,field.Hwnd)
    A_Clipboard := "RESTORE SEED"
    RunConvert()
    Sleep(80)
    if field.Value != "no selection" || A_Clipboard != "RESTORE SEED"
        throw Error("No-selection scenario changed data")
    FileAppend("PASS: selection-to-paste conversion fixture.`n","*","UTF-8")
    fixture.Destroy()
    ToastManager.DismissAll()
    ExitApp(0)
} catch as err {
    FileAppend("FAIL: " err.Message "`n","*","UTF-8")
    fixture.Destroy()
    ToastManager.DismissAll()
    ExitApp(1)
}
