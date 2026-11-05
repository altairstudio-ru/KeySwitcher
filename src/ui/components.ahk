#Requires AutoHotkey v2.0
; ============================================================
;  ui/components.ahk  —  Reusable UI Components
;  Buttons, Toggles, HotkeyEditor, Slider, Toast, TrayMenu, etc.
; ============================================================

#Requires AutoHotkey v2.0

; ============================================================
;  Base Component Mixin
; ============================================================

class ComponentBase {
    GetThemeColor(token, alpha := "") {
        return DesignTokens.GetColor(token, DesignTokens.IsDarkMode, alpha)
    }
    
    GetThemeTextColor(token) {
        return DesignTokens.GetTextColor(token, DesignTokens.IsDarkMode)
    }
    
    GetSpace(n) {
        return DesignTokens.Space(n)
    }
    
    GetRadius(name) {
        return DesignTokens.Radius(name)
    }
    
    GetTypography(role) {
        return DesignTokens.Typography(role)
    }

    SetVisible(visible) {
        this.Control.Visible := !!visible
    }
}

; ============================================================
;  GlassCard - Frosted glass container with specular highlight
;  Uses Progress control as background for colored panel effect
; ============================================================

class GlassCard extends ComponentBase {
    __New(parent, options := {}) {
        this.Parent := parent
        this.Options := options
        this.Controls := []
        this.Hwnd := 0
        this._bgCtrl := 0
        this._CreateCard()
    }
    
    _CreateCard() {
        opts := this.Options
        x := GetOption(opts, "x", 0)
        y := GetOption(opts, "y", 0)
        w := GetOption(opts, "w", 200)
        h := GetOption(opts, "h", 100)
        name := GetOption(opts, "name", "")
        
        ; Create a Progress control as the glass background
        bgOpts := "x" x " y" y " w" w " h" h
        if name
            bgOpts .= " v" name "_bg"
        
        bgColor := this.GetThemeTextColor("bg-card")
        
        ; Fill with the card surface, not an opaque border-colored bar.
        this._bgCtrl := GlassPaint.Surface(this.Parent, x, y, w, h)
        this.Hwnd := this._bgCtrl.Hwnd
        
        ; GroupBox on top for border (optional, invisible)
        gbOpts := "Section x" x " y" y " w" w " h" h
        if name
            gbOpts .= " v" name "_gb"
        this.Container := this.Parent.AddText(gbOpts " BackgroundTrans Hidden", "")
    }
    
    _StyleCard() {
        ; Background is already applied via Progress control
    }
    
    ; Explicit numeric x/y are card-local; relative AHK options stay relative.
    _OffsetOptions(options) {
        for axis in ["x", "y"] {
            pattern := "i)(^|\s)" axis "(-?\d+(?:\.\d+)?)(?=\s|$)"
            if RegExMatch(options, pattern, &match) {
                position := GetOption(this.Options, axis, 0) + Number(match[2])
                options := RegExReplace(options, pattern, "${1}" axis position, , 1)
            }
        }
        return options
    }

    ; Content addition methods - add to parent but track for visibility.
    AddText(options, text) {
        ctrl := this.Parent.AddText(this._OffsetOptions(options), text)
        this.Controls.Push(ctrl)
        return ctrl
    }
    
    AddEdit(options, text := "") {
        ctrl := this.Parent.AddEdit(this._OffsetOptions(options), text)
        this.Controls.Push(ctrl)
        return ctrl
    }
    
    AddButton(options, text) {
        ctrl := this.Parent.AddButton(this._OffsetOptions(options), text)
        this.Controls.Push(ctrl)
        return ctrl
    }
    
    AddCheckbox(options, text) {
        ctrl := this.Parent.AddCheckbox(this._OffsetOptions(options), text)
        this.Controls.Push(ctrl)
        return ctrl
    }

    AddHotkey(options, value := "") {
        ctrl := this.Parent.AddHotkey(this._OffsetOptions(options), value)
        this.Controls.Push(ctrl)
        return ctrl
    }
    
    AddProgress(options, value := 100) {
        ctrl := this.Parent.AddProgress(this._OffsetOptions(options), value)
        this.Controls.Push(ctrl)
        return ctrl
    }
    
    AddPicture(options, path) {
        ctrl := this.Parent.AddPicture(this._OffsetOptions(options), path)
        this.Controls.Push(ctrl)
        return ctrl
    }
    
    AddSlider(options, initial := 0) {
        ctrl := this.Parent.AddSlider(this._OffsetOptions(options), initial)
        this.Controls.Push(ctrl)
        return ctrl
    }
    
    SetFont(options, family := "") {
        return this.Parent.SetFont(options, family)
    }
    
    SetVisible(visible) {
        this._bgCtrl.Visible := visible
        this.Container.Visible := visible
        for ctrl in this.Controls
            ctrl.Visible := visible
    }
}

; ============================================================
;  PrimaryButton - Accent button with hover/pressed states
; ============================================================

class PrimaryButton extends ComponentBase {
    __New(parent, text, options := {}) {
        this.Parent := parent
        this.Text := text
        this.Options := options
        this.Callback := GetOption(options, "OnClick", "")
        this.Control := 0
        this._CreateButton()
    }
    
    _CreateButton() {
        opts := this.Options
        x := GetOption(opts, "x", "")
        y := GetOption(opts, "y", "")
        w := GetOption(opts, "w", "")
        h := GetOption(opts, "h", "40")
        name := GetOption(opts, "name", "")
        
        btnOpts := ""
        if x != ""
            btnOpts .= " x" x
        if y != ""
            btnOpts .= " y" y
        if w != ""
            btnOpts .= " w" w
        if h != ""
            btnOpts .= " h" h
        if name
            btnOpts .= " v" name
        
        ; Default style: no border, accent background
        this.Control := this.Parent.AddButton(btnOpts, this.Text)
        if !DesignTokens.HighContrast
            GlassPaint.Attach(this.Control, "primary")
        
        ; Style via colors (limited in AHK)
        accent := this.GetThemeColor("accent")
        onAccent := this.GetThemeTextColor("fg-on-accent")
        
        ; AHK Button coloring is limited
        ; We set the GUI's default button color via stylesheet workaround
        ; For now, rely on system theming
        
        if this.Callback
            this.Control.OnEvent("Click", (*) => this.Callback.Call())
        
        ; Hover/pressed feedback via cursor
        ; hover events don't exist for v2 Button — no-op
    }
    
    _OnHover(enter) {
        ; Visual feedback would need owner-draw or subclassing
        ; Placeholder for future enhancement
    }
    
    SetEnabled(enabled) {
        this.Control.Enabled := enabled
        this.Control.Text := enabled ? this.Text : this.Text
    }
    
    SetText(text) {
        this.Text := text
        this.Control.Text := text
    }
}

; ============================================================
;  SecondaryButton - Ghost/outline button
; ============================================================

class SecondaryButton extends ComponentBase {
    __New(parent, text, options := {}) {
        this.Parent := parent
        this.Text := text
        this.Options := options
        this.Callback := GetOption(options, "OnClick", "")
        this.Control := 0
        this._CreateButton()
    }
    
    _CreateButton() {
        opts := this.Options
        btnOpts := ""
        for key in ["x", "y", "w", "h"] {
            if HasOption(opts, key)
                btnOpts .= " " key GetOption(opts, key)
        }
        if GetOption(opts, "name", "") != ""
            btnOpts .= " v" GetOption(opts, "name")
        
        this.Control := this.Parent.AddButton(btnOpts, this.Text)
        if !DesignTokens.HighContrast
            GlassPaint.Attach(this.Control, "secondary")
        
        if this.Callback
            this.Control.OnEvent("Click", (*) => this.Callback.Call())
    }
}

; ============================================================
;  ToggleSwitch - iOS-style animated toggle
; ============================================================

class ToggleSwitch extends ComponentBase {
    __New(parent, text, options := {}) {
        this.Parent := parent
        this.Text := text
        this.Options := options
        this.Value := GetOption(options, "Value", 0)
        this.Callback := GetOption(options, "OnChange", "")
        this.Control := 0
        this._Label := 0
        this._CreateToggle()
    }
    
    _CreateToggle() {
        opts := this.Options
        x := GetOption(opts, "x", 0)
        y := GetOption(opts, "y", 0)
        w := GetOption(opts, "w", 280)
        h := GetOption(opts, "h", 24)
        name := GetOption(opts, "name", "")

        ; The requested width covers both the box and its clickable label.
        cbOpts := "x" x " y" y " w" w " h" h
        if name
            cbOpts .= " v" name
        this.Parent.SetFont("s10 norm c" this.GetThemeTextColor("fg-primary"), "Segoe UI")
        this.Control := this.Parent.AddCheckbox(cbOpts, this.Text)
        this.Control.Value := this.Value
        this.Control.OnEvent("Click", (ctrl, *) => this._OnChange(ctrl.Value))
        if !DesignTokens.HighContrast
            GlassPaint.AttachToggle(this.Control)
    }
    
    _OnChange(value) {
        this.Value := value
        this.Control.Redraw()
        if this.Callback
            this.Callback.Call(value)
    }
    
    GetValue() {
        return this.Control.Value
    }

    SetValue(value) {
        this.Value := !!value
        this.Control.Value := this.Value
        this.Control.Redraw()
    }

    _Draw(ctrl, nm, *) {
        return GlassPaint.DrawToggle(ctrl, nm)
    }
}

; ============================================================
;  HotkeyEditor - Visual hotkey input with modifier badges
; ============================================================

class HotkeyEditor extends ComponentBase {
    static Active := 0
    static ActivateHandler := 0

    __New(parent, label, currentHotkey, options := {}) {
        this.Parent := parent
        this.Label := label
        this.Hotkey := currentHotkey
        this.Options := options
        this.Callback := GetOption(options, "OnChange", "")
        this.IsEditing := false
        this.CapturedKeys := []
        this.Hook := 0
        this.CaptureTimer := 0
        this.Pending := ""
        this.PendingVK := 0
        this.WasSuspended := false
        this.DefaultValue := GetOption(options, "DefaultValue", currentHotkey)
        this.Control := 0
        this.DisplayCtrl := 0
        this._CreateEditor()
    }
    
    _CreateEditor() {
        opts := this.Options
        x := GetOption(opts, "x", 0)
        y := GetOption(opts, "y", 0)
        w := GetOption(opts, "w", 220)
        h := GetOption(opts, "h", 40)
        name := GetOption(opts, "name", "")
        this.LabelCtrl := 0
        this.Parent.SetFont("s10 norm c" this.GetThemeTextColor("fg-primary"), "Segoe UI")
        if this.Label != "" {
            this.LabelCtrl := this.Parent.AddText("x" x " y" y " w" w " h22", this.Label)
            y += 28
        }

        ; Native buttons preserve Tab, Space/Enter and their accessible names.
        resetW := 92
        gap := DesignTokens.Space(2)
        inputW := Max(80, w - resetW - gap)
        hkOpts := "x" x " y" y " w" inputW " h" h
        if name
            hkOpts .= " v" name "_hk"
        this.Control := this.Parent.AddButton(hkOpts, "")
        if !DesignTokens.HighContrast
            GlassPaint.Attach(this.Control, "hotkey")
        this.Reset := SecondaryButton(this.Parent,"Сбросить",{
            x:x+inputW+gap,y:y,w:resetW,h:h,OnClick:(*) => this.ResetValue()})
        this.DisplayCtrl := this.Control
        this.SetValue(this.Hotkey)
        this.Control.OnEvent("Click", (*) => this.BeginCapture())
        this.Control.OnEvent("LoseFocus", (*) => this.CancelCapture())
    }

    _OnChange() {
        if this.Callback
            this.Callback.Call(this.Hotkey)
    }

    GetValue() => this.Hotkey

    SetValue(hk) {
        this.CancelCapture()
        this.Hotkey := hk
        this._Refresh()
    }

    static Parts(hk) {
        parts := []
        modifiers := RegExReplace(hk,"[^\^!+#].*$")
        for modifier in [["^","Ctrl"],["!","Alt"],["+","Shift"],["#","Win"]] {
            if InStr(modifiers,modifier[1])
                parts.Push(modifier[2])
        }
        key := RegExReplace(hk,"^[\^!+#]*")
        if key != "" {
            display := GetKeyName(key)
            parts.Push(StrLen(display)=1 ? StrUpper(display) : display)
        }
        return parts
    }

    _Refresh() {
        this.Control.Text := this.IsEditing ? "Нажмите сочетание… · Esc — отмена" :
            (this.Hotkey = "" ? "Назначить сочетание…" : UI_HotkeyToDisplay(this.Hotkey))
        if GlassPaint.Items.Has(this.Control.Hwnd) {
            item := GlassPaint.Items[this.Control.Hwnd]
            item.parts := this.IsEditing ? [] : HotkeyEditor.Parts(this.Hotkey)
            item.recording := this.IsEditing
        }
        this.Control.Redraw()
    }

    BeginCapture() {
        if this.IsEditing
            return
        if IsObject(HotkeyEditor.Active)
            HotkeyEditor.Active.CancelCapture()
        if !HotkeyEditor.ActivateHandler {
            HotkeyEditor.ActivateHandler := ObjBindMethod(HotkeyEditor,"_ActivationChanged")
            OnMessage(0x6,HotkeyEditor.ActivateHandler)
        }
        this.Control.Focus()
        this.WasSuspended := A_IsSuspended
        this.IsEditing := true
        this.Pending := "", this.PendingVK := 0
        HotkeyEditor.Active := this
        try {
            ; Suppress application actions only while the focused field records.
            Suspend(true)
            this.Hook := InputHook("L0 T15")
            this.Hook.KeyOpt("{All}","NS")
            this.Hook.OnKeyDown := ObjBindMethod(this,"_KeyDown")
            this.Hook.OnKeyUp := ObjBindMethod(this,"_KeyUp")
            this.Hook.OnEnd := (*) => this.CancelCapture()
            this.CaptureTimer := ObjBindMethod(this,"_CheckFocus")
            SetTimer(this.CaptureTimer,100)
            this._Refresh()
            this.Hook.Start()
        } catch as err {
            this.CancelCapture()
            throw err
        }
    }

    _CheckFocus() {
        if !WinActive("ahk_id " this.Parent.Hwnd) || !this.Control.Visible
            || DllCall("GetFocus","Ptr") != this.Control.Hwnd
            this.CancelCapture()
    }

    static _ActivationChanged(wParam,lParam,msg,hwnd) {
        if (wParam & 0xFFFF)=0
            this.CancelForWindow(hwnd)
    }

    static Compose(vk, sc, mods) {
        ; Serialize letters by virtual key, independent of RU/EN input layout.
        key := vk >= 0x41 && vk <= 0x5A ? Chr(vk) : GetKeyName(Format("vk{:X}sc{:X}",vk,sc))
        return key = "" ? "" : mods key
    }

    _KeyDown(hook, vk, sc) {
        this._CheckFocus()
        if !this.IsEditing || this.PendingVK
            return
        if vk=0x10 || vk=0x11 || vk=0x12 || (vk>=0xA0 && vk<=0xA5) || vk=0x5B || vk=0x5C
            return
        mods := (GetKeyState("Ctrl","P") ? "^" : "")
            . (GetKeyState("Alt","P") ? "!" : "")
            . (GetKeyState("Shift","P") ? "+" : "")
            . (GetKeyState("LWin","P") || GetKeyState("RWin","P") ? "#" : "")
        if vk=0x1B && mods="" {
            this.CancelCapture()
            return
        }
        if vk=9 {
            this.CancelCapture()
            this.Reset.Control.Focus()
            return
        }
        this.Pending := HotkeyEditor.Compose(vk,sc,mods)
        this.PendingVK := vk
    }

    _KeyUp(hook,vk,sc) {
        this._CheckFocus()
        if this.IsEditing && this.PendingVK = vk {
            value := this.Pending
            this.CancelCapture()
            if value != "" {
                this.SetValue(value)
                this._OnChange()
            }
        }
    }

    CancelCapture() {
        if !this.IsEditing
            return
        this.IsEditing := false
        if this.CaptureTimer
            SetTimer(this.CaptureTimer,0)
        this.CaptureTimer := 0
        if IsObject(this.Hook) {
            this.Hook.OnEnd := ""
            this.Hook.OnKeyDown := ""
            this.Hook.OnKeyUp := ""
            this.Hook.Stop()
        }
        this.Hook := 0
        this.Pending := "", this.PendingVK := 0
        Suspend(this.WasSuspended)
        HotkeyEditor.Active := 0
        this._Refresh()
    }

    ResetValue() {
        this.SetValue(this.DefaultValue)
        this._OnChange()
    }

    static CancelForWindow(hwnd) {
        if IsObject(this.Active) && this.Active.Parent.Hwnd = hwnd
            this.Active.CancelCapture()
    }

    SetVisible(visible) {
        super.SetVisible(visible)
        if !visible
            this.CancelCapture()
        this.Reset.SetVisible(visible)
        this.DisplayCtrl.Visible := !!visible
        if this.LabelCtrl
            this.LabelCtrl.Visible := !!visible
    }
}

; ============================================================
;  Slider - Custom styled slider with value tooltip
; ============================================================

class Slider extends ComponentBase {
    __New(parent, label, min, max, current, options := {}) {
        this.Parent := parent
        this.Label := label
        this.Min := min
        this.Max := max
        this.Value := current
        this.Options := options
        this.Callback := GetOption(options, "OnChange", "")
        this.Control := 0
        this.ValueLabel := 0
        this._CreateSlider()
    }
    
    _CreateSlider() {
        opts := this.Options
        x := GetOption(opts, "x", 0)
        y := GetOption(opts, "y", 0)
        w := GetOption(opts, "w", 280)
        name := GetOption(opts, "name", "")
        this.LabelCtrl := 0
        this.Parent.SetFont("s10 norm c" this.GetThemeTextColor("fg-primary"), "Segoe UI")
        if this.Label != "" {
            this.LabelCtrl := this.Parent.AddText("x" x " y" y " w" w " h22", this.Label)
            y += 28
        }

        sOpts := "x" x " y" y " w" w " AltSubmit Range" this.Min "-" this.Max
        if name
            sOpts .= " v" name
        this.Control := this.Parent.AddSlider(sOpts, this.Value)
        this.Value := this.Control.Value
        valX := x + w + DesignTokens.Space(2)
        this.ValueLabel := this.Parent.AddText("x" valX " y" y " w60 h22 Right", this.Value)
        this.Control.OnEvent("Change", (ctrl, *) => this._OnChange(ctrl.Value))
    }
    
    _OnChange(value) {
        this.Value := value
        this.ValueLabel.Text := value
        if this.Callback
            this.Callback.Call(value)
    }
    
    GetValue() {
        return this.Control.Value
    }

    SetValue(value) {
        this.Control.Value := Max(this.Min, Min(this.Max, value))
        this.Value := this.Control.Value
        this.ValueLabel.Text := this.Value
    }

    SetVisible(visible) {
        super.SetVisible(visible)
        this.ValueLabel.Visible := !!visible
        if this.LabelCtrl
            this.LabelCtrl.Visible := !!visible
    }
}

; ============================================================
;  ToastManager - Glass toast notifications
; ============================================================

class ToastManager {
    static Toasts := []
    static Container := 0
    static MaxToasts := 5
    static DefaultDuration := 3000

    static Show(message, options := {}) {
        toast := ToastManager.Toast(message, options)
        ToastManager.Toasts.Push(toast)
        while ToastManager.Toasts.Length > Max(1, ToastManager.MaxToasts)
            ToastManager.Toasts[1].Dismiss()
        ToastManager._RepositionStack()
        if toast.Duration > 0 {
            ; Retain the callable, not SetTimer's (empty) return value.
            toast.Timer := ObjBindMethod(toast, "Dismiss")
            SetTimer(toast.Timer, -Max(1, Round(toast.Duration)))
            toast.ProgressTimer := ObjBindMethod(toast, "UpdateProgress")
            SetTimer(toast.ProgressTimer, 50)
        }
        return toast
    }

    static _RepositionStack() {
        MonitorGetWorkArea(MonitorGetPrimary(), &left, &top, &right, &bottom)
        ; Work area/window rectangles are physical pixels; GUI layout uses DIPs.
        scale := A_ScreenDPI / 96
        margin := Round(DesignTokens.Space(6) * scale)
        gap := Round(DesignTokens.Space(2) * scale)
        y := bottom - margin
        count := ToastManager.Toasts.Length
        Loop count {
            toast := ToastManager.Toasts[count - A_Index + 1]
            rect := Buffer(16, 0)
            DllCall("user32\GetWindowRect", "Ptr", toast.Gui.Hwnd, "Ptr", rect)
            width := NumGet(rect, 8, "Int") - NumGet(rect, 0, "Int")
            height := NumGet(rect, 12, "Int") - NumGet(rect, 4, "Int")
            y -= height
            x := Max(left, right - margin - width)
            ; SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_SHOWWINDOW.
            DllCall("user32\SetWindowPos", "Ptr", toast.Gui.Hwnd, "Ptr", 0,
                "Int", x, "Int", Max(top, y), "Int", 0, "Int", 0, "UInt", 0x55)
            y -= gap
        }
    }

    static DismissAll() {
        while ToastManager.Toasts.Length
            ToastManager.Toasts[ToastManager.Toasts.Length].Dismiss()
    }

    class Toast {
        __New(message, options) {
            this.Message := message
            this.Duration := GetOption(options, "Duration", ToastManager.DefaultDuration)
            this.Timer := 0
            this.ProgressTimer := 0
            this.Closed := false
            this.Started := A_TickCount
            this.ActionCallback := GetOption(options, "ActionCallback", "")
            icon := GetOption(options, "Icon", "")
            actionText := GetOption(options, "ActionText", "")
            isDark := DesignTokens.IsDarkMode
            bgColor := DesignTokens.GetTextColor("bg-card", isDark)
            textColor := DesignTokens.GetTextColor("fg-primary", isDark)
            accentColor := DesignTokens.GetTextColor("accent", isDark)
            this.Gui := Gui("+AlwaysOnTop -Caption -Border +ToolWindow +E0x08000000", "KeySwitcher")
            this.Gui.BackColor := bgColor
            this.Gui.MarginX := 0
            this.Gui.MarginY := 0
            this.Gui.SetFont("s10 norm c" textColor, "Segoe UI")
            padding := DesignTokens.Space(3)
            width := DesignTokens.Sizing["toast-max-width"]
            x := padding
            if icon != "" {
                if FileExist(icon)
                    this.Gui.AddPicture("x" x " y" padding " w20 h20", icon)
                else
                    this.Gui.AddText("x" x " y" padding " w28 h22", icon)
                x += 28 + DesignTokens.Space(2)
            }
            messageWidth := Max(40, width - x - padding - (actionText != "" ? 88 : 0))
            msg := this.Gui.AddText("x" x " y" padding " w" messageWidth, message)
            msg.GetPos(, , , &messageHeight)
            height := Max(28, messageHeight) + padding * 2 + 5
            if actionText != "" {
                this.ActionBtn := this.Gui.AddButton("x" (width - padding - 80) " y" padding " w80 h28", actionText)
                this.ActionBtn.OnEvent("Click", ObjBindMethod(this, "_RunAction"))
            }
            this.Progress := this.Gui.AddProgress("x" padding " y" (height - 4)
                " w" (width - padding * 2) " h3 Background" bgColor " c" accentColor, 100)
            this.Progress.Visible := this.Duration > 0
            this.Gui.OnEvent("Close", ObjBindMethod(this, "Dismiss"))
            this.Gui.OnEvent("Escape", ObjBindMethod(this, "Dismiss"))
            this.Gui.Show("Hide w" width " h" height)
            if !DesignTokens.HighContrast {
                rect := Buffer(16,0)
                DllCall("GetClientRect","Ptr",this.Gui.Hwnd,"Ptr",rect)
                radius := Round(24*A_ScreenDPI/96)
                region := DllCall("CreateRoundRectRgn","Int",0,"Int",0,"Int",NumGet(rect,8,"Int")+1,
                    "Int",NumGet(rect,12,"Int")+1,"Int",radius,"Int",radius,"Ptr")
                if !DllCall("SetWindowRgn","Ptr",this.Gui.Hwnd,"Ptr",region,"Int",true)
                    DllCall("DeleteObject","Ptr",region)
            }
        }

        _RunAction(*) {
            try {
                if this.ActionCallback
                    this.ActionCallback.Call()
            } finally {
                this.Dismiss()
            }
        }

        UpdateProgress(*) {
            if !this.Closed
                this.Progress.Value := Max(0, 100 - (A_TickCount - this.Started) * 100 / this.Duration)
        }

        Dismiss(*) {
            if this.Closed
                return
            this.Closed := true
            if this.Timer
                SetTimer(this.Timer, 0)
            if this.ProgressTimer
                SetTimer(this.ProgressTimer, 0)
            this.Timer := 0
            this.ProgressTimer := 0
            for i, toast in ToastManager.Toasts {
                if toast = this {
                    ToastManager.Toasts.RemoveAt(i)
                    break
                }
            }
            this.Gui.Destroy()
            ToastManager._RepositionStack()
        }

        AnimateIn(*) {
            if !this.Closed
                ToastManager._RepositionStack()
        }

        AnimateOut(*) {
            this.Dismiss()
        }
    }
}

; ============================================================
;  TrayMenu - Fluent-styled system tray menu
; ============================================================

class FluentTrayMenu {
    static Items := []
    static Menu := 0
    
    static Create() {
        ; AHK's native tray menu is limited
        ; For Fluent styling, we'd need a custom GUI popup
        ; This provides the structure; actual implementation uses native menu
        tray := A_TrayMenu
        tray.Delete()
        
        ; We'll enhance with icons and checkmarks where possible
        return tray
    }
    
    static AddItem(text, callback, options := {}) {
        item := {
            Text: text,
            Callback: callback,
            Icon: GetOption(options, "Icon", ""),
            Checked: GetOption(options, "Checked", false),
            Disabled: GetOption(options, "Disabled", false),
            Submenu: GetOption(options, "Submenu", [])
        }
        FluentTrayMenu.Items.Push(item)
        return item
    }
    
    static AddSeparator() {
        FluentTrayMenu.Items.Push({ IsSeparator: true })
    }
    
    static Build(tray := 0) {
        tray := tray ?? A_TrayMenu
        tray.Delete()
        
        for item in FluentTrayMenu.Items {
            if item.IsSeparator {
                tray.Add()
                continue
            }
            
            ; AHK tray menu: Add(text, callback)
            ; Icons not directly supported in standard menu
            if item.Callback
                tray.Add(item.Text, item.Callback)
            else
                tray.Add(item.Text)
            
            ; Check state (visual only in some contexts)
            if item.Checked
                tray.Check(item.Text)
            
            if item.Disabled
                tray.Disable(item.Text)
        }
    }
    
    static UpdateItem(text, options := {}) {
        for item in FluentTrayMenu.Items {
            if item.Text = text {
                if HasOption(options, "Checked")
                    item.Checked := options.Checked
                if HasOption(options, "Disabled")
                    item.Disabled := options.Disabled
                if HasOption(options, "Text")
                    item.Text := options.Text
                break
            }
        }
        FluentTrayMenu.Build()
    }
}

; ============================================================
;  SearchBox - Live search with Ctrl+F support
; ============================================================

class SearchBox extends ComponentBase {
    __New(parent, placeholder, options := {}) {
        this.Parent := parent
        this.Placeholder := placeholder
        this.Options := options
        this.Callback := GetOption(options, "OnSearch", "")
        this.Control := 0
        this._CreateSearchBox()
    }
    
    _CreateSearchBox() {
        opts := this.Options
        x := GetOption(opts, "x", "")
        y := GetOption(opts, "y", "")
        w := GetOption(opts, "w", "240")
        h := GetOption(opts, "h", "32")
        name := GetOption(opts, "name", "")
        
        ; Search input with native cue-banner placeholder
        editOpts := "w" w " h" h
        if x != ""
            editOpts .= " x" x
        if y != ""
            editOpts .= " y" y
        if name
            editOpts .= " v" name
        this.Control := this.Parent.AddEdit(editOpts, "")
        this.Control.Opt("Background" this.GetThemeTextColor("bg-card") " c" this.GetThemeTextColor("fg-primary"))
        DllCall("user32\SendMessageW", "Ptr", this.Control.Hwnd, "UInt", 0x1501, "Ptr", 0, "WStr", this.Placeholder)
        this.Control.OnEvent("Change", ObjBindMethod(this, "_OnChange"))
    }
    
    _OnChange(ctrl, *) {
        if this.Callback
            this.Callback.Call(ctrl.Text)
    }
    
    GetValue() {
        return this.Control.Text
    }
    
    Clear() {
        this.Control.Text := ""
    }
}

; ============================================================
;  SectionHeader - Consistent section heading
; ============================================================

class SectionHeader extends ComponentBase {
    __New(parent, title, options := {}) {
        this.Parent := parent
        this.Title := title
        this.Options := options
        this._CreateHeader()
    }
    
    _CreateHeader() {
        opts := this.Options
        x := GetOption(opts, "x", DesignTokens.Space(6))
        y := GetOption(opts, "y", 0)
        w := GetOption(opts, "w", 0)
        
        this.Parent.SetFont("s16 bold", "Segoe UI Variable")
        fg := this.GetThemeTextColor("fg-primary")
        this.Control := this.Parent.AddText("x" x " y" y " w" w " h28 c" fg, this.Title)
    }
}

; ============================================================
;  Divider - Subtle section divider
; ============================================================

class Divider extends ComponentBase {
    __New(parent, options := {}) {
        this.Parent := parent
        this.Options := options
        this._CreateDivider()
    }
    
    _CreateDivider() {
        opts := this.Options
        x := GetOption(opts, "x", DesignTokens.Space(6))
        y := GetOption(opts, "y", 0)
        w := GetOption(opts, "w", 0)
        
        color := this.GetThemeTextColor("divider")
        ; Use Progress as a thin line
        this.Control := this.Parent.AddProgress("x" x " y" y " w" w " h1 Background" color " c" color, 100)
    }
}

; ============================================================
;  ConfigPathDisplay - Selectable config file path
; ============================================================

class ConfigPathDisplay extends ComponentBase {
    __New(parent, path, options := {}) {
        this.Parent := parent
        this.Path := path
        this.Options := options
        this._CreateDisplay()
    }
    
    _CreateDisplay() {
        opts := this.Options
        x := GetOption(opts, "x", DesignTokens.Space(6))
        y := GetOption(opts, "y", 0)
        w := GetOption(opts, "w", 0)
        
        this.Parent.SetFont("s12", "Cascadia Mono")
        fg := this.GetThemeTextColor("fg-tertiary")
        this.Control := this.Parent.AddText("x" x " y" y " w" w " h20 c" fg, this.Path)
        
        ; Click to copy
        this.Control.OnEvent("Click", ObjBindMethod(this, "_CopyPath"))
    }
    
    _CopyPath(*) {
        A_Clipboard := this.Path
        ToastManager.Show("Путь скопирован в буфер обмена")
    }
}

; ============================================================
;  FooterActions - Standard dialog footer with Cancel/Save
; ============================================================

class FooterActions extends ComponentBase {
    __New(parent, onSave, onCancel, options := {}) {
        this.Parent := parent
        this.OnSave := onSave
        this.OnCancel := onCancel
        this.Options := options
        this.SaveBtn := 0
        this.CancelBtn := 0
        this._CreateFooter()
    }
    
    _CreateFooter() {
        opts := this.Options
        x := GetOption(opts, "x", 0)
        y := GetOption(opts, "y", 0)
        w := GetOption(opts, "w", 0)
        rightAlign := GetOption(opts, "RightAlign", true)
        
        btnH := DesignTokens.Sizing["button-height"]
        btnW := 104
        gap := DesignTokens.Space(3)
        
        if rightAlign {
            xSave := x + w - btnW
            xCancel := xSave - btnW - gap
        } else {
            xCancel := x
            xSave := x + btnW + gap
        }
        
        ; Cancel (secondary)
        this.CancelBtn := SecondaryButton(this.Parent, GetOption(opts, "CancelText", "Отмена"), {
            x: xCancel, y: y, w: btnW, h: btnH,
            OnClick: this.OnCancel
        }).Control
        
        ; Save (primary)
        this.SaveBtn := PrimaryButton(this.Parent, GetOption(opts, "SaveText", "Сохранить"), {
            x: xSave, y: y, w: btnW, h: btnH,
            OnClick: this.OnSave
        }).Control
        
        ; Default button (Enter key)
        this.SaveBtn.Opt("+Default")
    }
    
    SetSaveEnabled(enabled) {
        this.SaveBtn.Enabled := enabled
    }

    SetVisible(visible) {
        this.SaveBtn.Visible := !!visible
        this.CancelBtn.Visible := !!visible
    }
}

; ============================================================
;  TabBar - Glass tab navigation
; ============================================================

class TabBar extends ComponentBase {
    __New(parent, tabs, options := {}) {
        this.Parent := parent
        this.Tabs := tabs  ; Array of {id, label, icon}
        this.Options := options
        this.Selected := GetOption(options, "Selected", tabs.Length ? tabs[1].id : "")
        this.Callback := GetOption(options, "OnChange", "")
        this.Controls := []
        this._CreateTabBar()
    }
    
    _CreateTabBar() {
        opts := this.Options
        x := GetOption(opts, "x", DesignTokens.Space(6))
        y := GetOption(opts, "y", 0)
        count := this.Tabs.Length
        if !count
            return
        gap := DesignTokens.Space(2)
        width := GetOption(opts, "w", count * 140 + (count - 1) * gap)
        available := width - (count - 1) * gap
        this.Visible := true
        this.Parent.SetFont("s10 norm", "Segoe UI")
        for i, tab in this.Tabs {
            selected := tab.id = this.Selected
            tabW := Floor(available * i / count) - Floor(available * (i - 1) / count)
            tabX := x + Floor(available * (i - 1) / count) + (i - 1) * gap
            btn := this._CreateTabButton(tab, GetOption(tab, "icon", ""), tabX, y, selected, tabW)
            ; GetPos returns GUI coordinates, already including a card's offset.
            btn.GetPos(&bx, &by, &bw, &bh)
            accent := this.GetThemeTextColor("accent")
            indicator := this.Parent.AddProgress("x" tabX " y" (y + bh - 2) " w" bw
                " h2 Background" accent " c" accent, 100)
            indicator.Visible := false
            this.Controls.Push({id: tab.id, btn: btn, indicator: indicator})
        }
    }

    _CreateTabButton(tab, icon, x, y, selected, width := 140) {
        label := tab.label
        btn := this.Parent.AddButton("x" x " y" y " w" width " h36", label)
        if !DesignTokens.HighContrast
            GlassPaint.Attach(btn, "segment", selected)
        btn.SetFont(selected ? "bold" : "norm")
        btn.OnEvent("Click", ObjBindMethod(this, "_TabClick", tab.id))
        return btn
    }

    _TabClick(id, *) {
        this._SelectTab(id)
    }

    _SelectTab(id) {
        if id = this.Selected
            return
        found := false
        for tabCtrl in this.Controls {
            if tabCtrl.id = id
                found := true
        }
        if !found
            return
        this.Selected := id
        for tabCtrl in this.Controls {
            selected := tabCtrl.id = id
            tabCtrl.btn.SetFont(selected ? "bold" : "norm")
            tabCtrl.indicator.Visible := false
            GlassPaint.Select(tabCtrl.btn, selected)
        }
        if this.Callback
            this.Callback.Call(id)
    }

    GetSelected() {
        return this.Selected
    }

    SetVisible(visible) {
        this.Visible := !!visible
        for tabCtrl in this.Controls {
            tabCtrl.btn.Visible := this.Visible
            tabCtrl.indicator.Visible := false
        }
    }
}

; ============================================================
;  Icon Helpers (ASCII/Text-based for 100% reliable rendering)
; ============================================================

class Icons {
    ; Simple text symbols that ALWAYS render correctly
    static Search        := "[?]"
    static Settings      := "[=]"
    static Info          := "[i]"
    static Close         := "[x]"
    static Check         := "[v]"
    static ChevronRight  := ">"
    static ChevronDown   := "v"
    static Keyboard      := "[K]"
    static Sound         := "[!]"
    static Mute          := "[/]"
    static Clipboard     := "[c]"
    static Swap          := "<=>"
    static Warning       := "[!]"
    static Error         := "[x]"
    static Success       := "[v]"
    static Link          := "[>]"
    static Folder        := "[+]"
    static File          := "[*]"
    static LightMode     := "[L]"
    static DarkMode      := "[D]"
    
    static Get(name, fallback := "") {
        return Icons.HasOwnProp(name) ? Icons.%name% : fallback
    }
}
