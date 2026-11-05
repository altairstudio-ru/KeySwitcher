#Requires AutoHotkey v2.0
; ============================================================
;  ui/core.ahk  —  Core UI Classes: GlassWindow, GlassPanel, Animation
;  Foundation for Windows 11 Fluent + iOS 26 Glassmorphism UI
; ============================================================

#Requires AutoHotkey v2.0

; ---- Option-map helpers (works with Map and plain Object) ----
HasOption(opts, key) {
    if !IsObject(opts)
        return false
    if Type(opts) = "Map"
        return opts.Has(key)
    return opts.HasOwnProp(key)
}

GetOption(opts, key, default := "") {
    if !IsObject(opts)
        return default
    if opts is Map
        return opts.Get(key, default)
    return opts.HasOwnProp(key) ? opts.%key% : default
}

; ---- DWM API Constants ----
DWMWA_USE_IMMERSIVE_DARK_MODE  := 20
DWMWA_MICA_EFFECT              := 1029
DWMWA_SYSTEMBACKDROP_TYPE      := 38
DWMSBT_AUTO                    := 0
DWMSBT_NONE                    := 1
DWMSBT_MAINWINDOW              := 2  ; Mica
DWMSBT_TRANSIENTWINDOW         := 3  ; Acrylic
DWMSBT_TABBEDWINDOW            := 4

; ---- Windows Version Detection ----
IsWindows11() {
    static version := 0
    if !version {
        version := DllCall("GetVersion", "UInt")
        ; Windows 11 = 10.0.22000+
        version := (version & 0xFFFF) >= 22000
    }
    return version
}

IsWindows10_1809() {
    ; Acrylic blur requires 1809+
    static version := 0
    if !version {
        version := DllCall("GetVersion", "UInt")
        version := (version & 0xFFFF) >= 17763
    }
    return version
}

; ---- High DPI Awareness ----
EnableHighDPI() {
    ; SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)
    DllCall("SetProcessDpiAwarenessContext", "Ptr", -4, "Ptr")
}

; ============================================================
;  Animation Helpers
; ============================================================

class Animation {
    static EaseOutCubic(t) {
        return 1 - (1 - t) ** 3
    }
    
    static EaseOutQuart(t) {
        return 1 - (1 - t) ** 4
    }
    
    static EaseOutSpring(t) {
        ; Approximate spring: cubic-bezier(0.34, 1.56, 0.64, 1)
        if t < 0.5
            return 2 * t * t * (1.56 * (1 - t) + 0.34)
        return 1 - 2 * (1 - t) * (1 - t) * (0.34 * t + 1.56 * (1 - t))
    }
    
    static Easing(fnName) {
        return Animation.HasFunc(fnName) ? Animation.%fnName% : Animation.EaseOutCubic
    }
    
    ; Animate a value over time
    static Animate(start, end, duration, easing, onUpdate, onComplete := "") {
        startTime := A_TickCount
        easingFn := Animation.Easing(easing)
        
        step() {
            elapsed := A_TickCount - startTime
            progress := elapsed / duration
            if progress >= 1 {
                onUpdate(end)
                if onComplete
                    onComplete()
                return false  ; Stop timer
            }
            t := easingFn(progress)
            current := start + (end - start) * t
            onUpdate(current)
            return true  ; Continue timer
        }
        
        ; Use high-resolution timer
        timer := SetTimer(step, 10)  ; ~60fps
        return timer
    }
    
    ; Fade control opacity (AHK Gui doesn't support per-control opacity easily)
    ; This is a placeholder for future enhancement
    static Fade(control, startOpacity, endOpacity, duration, easing := "EaseOutCubic") {
        ; AHK v2 Gui controls don't have Opacity property
        ; Would need layered window or custom drawing
    }
}

; ============================================================
;  Entrance Choreography
; ============================================================

class Entrance {
    static Stagger(controls, baseDelay := 40, direction := "up", distance := 8) {
        ; AHK doesn't have transform animations natively
        ; This provides the timing structure for future enhancement
        for i, ctrl in controls {
            delay := i * baseDelay
            ; In real implementation: slide from offset + fade in
            ; For now: just ensure visible
            ctrl.Visible := true
        }
    }
    
    static SlideFadeIn(control, delay := 0, direction := "up", distance := 8) {
        ; Placeholder for future animation support
        control.Visible := true
    }
    
    static WindowEntrance(window, onComplete := "") {
        ; Window-level entrance: fade + scale
        ; AHK Gui.Show() is instant, would need layered window for animation
        if onComplete
            onComplete()
    }
}

; ============================================================
;  GlassPanel - Reusable frosted glass container
; ============================================================

class GlassPanel {
    __New(parentGui, options := "") {
        this.Parent := parentGui
        this.Options := options
        this.Controls := []
        this.Hwnd := 0
        this._CreatePanel()
    }
    
    _CreatePanel() {
        ; Create a GroupBox as the panel container (no title)
        ; GroupBox provides a bordered container we can style
        opts := "Section"
        if HasOption(this.Options, "x")    opts .= " x" GetOption(this.Options, "x")
        if HasOption(this.Options, "y")    opts .= " y" GetOption(this.Options, "y")
        if HasOption(this.Options, "w")    opts .= " w" GetOption(this.Options, "w")
        if HasOption(this.Options, "h")    opts .= " h" GetOption(this.Options, "h")
        if HasOption(this.Options, "name") opts .= " v" GetOption(this.Options, "name")
        
        this.Control := this.Parent.AddGroupBox(opts, "")
        this.Hwnd := this.Control.Hwnd
        
        ; Apply glass styling via DWM (if supported) or fallback
        this._ApplyGlassStyle()
    }
    
    _ApplyGlassStyle() {
        if !this.Hwnd
            return
        
        ; Try to apply Mica/Acrylic to the panel's hwnd
        ; Note: DWM backdrop typically applies to top-level windows only
        ; For child panels, we simulate with background color + border
        this._ApplyFallbackStyle()
    }
    
    _ApplyFallbackStyle() {
        ; Apply visual glass effect via colors and borders
        isDark := DesignTokens.IsDarkMode
        bgColor := DesignTokens.GetColor("bg-card", isDark)
        borderColor := DesignTokens.GetColor("border-subtle", isDark)
        
        ; AHK GroupBox doesn't support background color directly
        ; We'll use a Progress control behind it for the fill
        ; This is handled by the parent window's layout system
    }
    
    AddControl(control) {
        this.Controls.Push(control)
        return control
    }
    
    AddText(options, text) {
        ctrl := this.Parent.AddText(options, text)
        this.Controls.Push(ctrl)
        return ctrl
    }
    
    AddEdit(options, text := "") {
        ctrl := this.Parent.AddEdit(options, text)
        this.Controls.Push(ctrl)
        return ctrl
    }
    
    AddButton(options, text) {
        ctrl := this.Parent.AddButton(options, text)
        this.Controls.Push(ctrl)
        return ctrl
    }
    
    AddCheckbox(options, text) {
        ctrl := this.Parent.AddCheckbox(options, text)
        this.Controls.Push(ctrl)
        return ctrl
    }
    
    AddProgress(options, value := 100) {
        ctrl := this.Parent.AddProgress(options, value)
        this.Controls.Push(ctrl)
        return ctrl
    }
    
    AddPicture(options, path) {
        ctrl := this.Parent.AddPicture(options, path)
        this.Controls.Push(ctrl)
        return ctrl
    }
    
    AddSlider(options, min := 0, max := 100) {
        ctrl := this.Parent.AddSlider(options, min, max)
        this.Controls.Push(ctrl)
        return ctrl
    }
}

; ============================================================
;  GlassWindow - Base window with Mica/Acrylic support
; ============================================================

class GlassWindow {
    __New(title, options := "") {
        this.Title := title
        this.Options := options
        this.Gui := 0
        this.Hwnd := 0
        this.Panels := []
        this._Animations := []
        this._CreateWindow()
    }
    
    _CreateWindow() {
        ; Build window options
        opts := "+OwnDialogs -MaximizeBox"
        if GetOption(this.Options, "resize", false)
            opts .= " +Resize"
        if GetOption(this.Options, "maximize", false)
            opts .= " +MaximizeBox"
        this.Shortcuts := []
        this.Gui := Gui(opts, this.Title)
        this.Hwnd := this.Gui.Hwnd
        GlassPaint.Init()
        GlassPaint.Windows[this.Hwnd] := this
        
        ; Apply theme-aware background
        this._ApplyTheme()
        
        ; Enable Mica/Acrylic backdrop (Windows 11+)
        this._EnableBackdrop()
        
        ; Set default font
        this.Gui.SetFont("s14", "Segoe UI Variable")
        
        ; Store reference for cleanup
        this.Gui.OnEvent("Close", this._OnClose.Bind(this))
        this.Gui.OnEvent("Escape", this._OnEscape.Bind(this))
    }
    
    _ApplyTheme() {
        this.Gui.BackColor := DesignTokens.GetTextColor("bg-canvas", DesignTokens.IsDarkMode)
    }
    
    _EnableBackdrop() {
        this.BackdropEnabled := false
        if VerCompare(A_OSVersion, "10.0.17763") < 0
            return
        dark := DesignTokens.IsDarkMode ? 1 : 0
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", this.Hwnd, "UInt", 20, "Int*", &dark, "UInt", 4)
        if VerCompare(A_OSVersion, "10.0.22000") >= 0 {
            corners := 2
            DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", this.Hwnd, "UInt", 33, "Int*", &corners, "UInt", 4)
        }
        if VerCompare(A_OSVersion, "10.0.22621") >= 0 {
            allowed := DesignTokens.Material = "glass" && !DesignTokens.HighContrast
                && RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "EnableTransparency", 1)
            backdrop := allowed ? 3 : 1
            result := DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", this.Hwnd, "UInt", 38, "Int*", &backdrop, "UInt", 4)
            ; Reserve the header for the system material; content stays opaque.
            margins := Buffer(16, 0)
            NumPut("Int", allowed ? Round(106 * A_ScreenDPI / 96) : 0, margins, 8)
            if result = 0 && allowed {
                DllCall("dwmapi\DwmExtendFrameIntoClientArea", "Ptr", this.Hwnd, "Ptr", margins)
                this.BackdropEnabled := true
            } else
                DllCall("dwmapi\DwmExtendFrameIntoClientArea", "Ptr", this.Hwnd, "Ptr", margins)
        }
    }
    
    _OnClose(*) {
        this.Destroy()
    }
    
    _OnEscape(*) {
        this.Destroy()
    }
    
    AddPanel(options := "") {
        panel := GlassPanel(this.Gui, options)
        this.Panels.Push(panel)
        return panel
    }
    
    ; Convenience methods that delegate to Gui
    AddText(options, text) {
        return this.Gui.AddText(options, text)
    }
    AddEdit(options, text := "") {
        return this.Gui.AddEdit(options, text)
    }
    AddButton(options, text) {
        return this.Gui.AddButton(options, text)
    }
    AddCheckbox(options, text) {
        return this.Gui.AddCheckbox(options, text)
    }
    AddProgress(options, v := 100) {
        return this.Gui.AddProgress(options, v)
    }
    AddPicture(options, path) {
        return this.Gui.AddPicture(options, path)
    }
    AddSlider(options, value := 0) {
        return this.Gui.AddSlider(options, value)
    }
    AddGroupBox(options, text) {
        return this.Gui.AddGroupBox(options, text)
    }
    AddTab3(options, text) {
        return this.Gui.AddTab3(options, text)
    }
    AddTab(options) {
        return this.Gui.AddTab(options)
    }
    AddListView(options, cols) {
        return this.Gui.AddListView(options, cols)
    }
    AddTreeView(options) {
        return this.Gui.AddTreeView(options)
    }
    AddUpDown(options, ctrl) {
        return this.Gui.AddUpDown(options, ctrl)
    }
    AddComboBox(options, items) {
        return this.Gui.AddComboBox(options, items)
    }
    AddListBox(options, items) {
        return this.Gui.AddListBox(options, items)
    }
    AddLink(options, text) {
        return this.Gui.AddLink(options, text)
    }
    AddHotkey(options, value := "") {
        return this.Gui.AddHotkey(options, value)
    }
    AddDateTime(options) {
        return this.Gui.AddDateTime(options)
    }
    AddMonthCal(options) {
        return this.Gui.AddMonthCal(options)
    }
    AddActiveX(options, clsid) {
        return this.Gui.AddActiveX(options, clsid)
    }
    
    SetFont(sizeWeight, family := "") {
        this.Gui.SetFont(sizeWeight, family)
    }
    
    OnEvent(event, callback) {
        this.Gui.OnEvent(event, callback)
    }
    
    Show(options := "") {
        ; Entrance animation would go here
        this.Gui.Show(options)
        
        ; Post-show: ensure backdrop is applied
        this._EnableBackdrop()
    }
    
    BindShortcut(key, callback) {
        HotIfWinActive("ahk_id " this.Hwnd)
        try Hotkey(key, callback)
        finally HotIf()
        this.Shortcuts.Push(key)
    }

    Destroy() {
        HotkeyEditor.CancelForWindow(this.Hwnd)
        GlassPaint.Release(this.Gui)
        HotIfWinActive("ahk_id " this.Hwnd)
        try {
            for key in this.Shortcuts
                Hotkey(key, "Off")
        } finally HotIf()
        for timer in this._Animations
            SetTimer(timer, 0)
        this.Gui.Destroy()
    }
    
    Center() {
        this.Gui.Show("Center")
    }
    
    ; Theme switching at runtime
    UpdateTheme() {
        this._ApplyTheme()
        this._EnableBackdrop()
        ; Would need to refresh all child panels
        for panel in this.Panels {
            panel._ApplyFallbackStyle()
        }
    }
}

; ============================================================
;  Layout Helpers
; ============================================================

class Layout {
    static Stack(parent, controls, options := {}) {
        ; Vertical stack with consistent spacing
        spacing := GetOption(options, "Spacing", DesignTokens.Space(4))
        startY := GetOption(options, "StartY", 0)
        x := GetOption(options, "X", 0)
        w := GetOption(options, "W", 0)
        
        y := startY
        for ctrl in controls {
            ctrlOpts := "x" x " y" y
            if w
                ctrlOpts .= " w" w
            ; Apply options to control (positioning handled by Gui)
            ; This is a conceptual helper; AHK uses absolute positioning
            y += ctrl.GetHeight() + spacing
        }
        return y
    }
    
    static Grid(parent, controls, cols, options := {}) {
        ; Grid layout helper
        gap := GetOption(options, "Gap", DesignTokens.Space(3))
        colW := GetOption(options, "ColWidth", 0)
        startX := GetOption(options, "StartX", 0)
        startY := GetOption(options, "StartY", 0)
        
        x := startX
        y := startY
        maxH := 0
        
        for i, ctrl in controls {
            col := Mod(i, cols)
            row := Floor(i / cols)
            
            if (col = 0) && (i > 0) {
                x := startX
                y += maxH + gap
                maxH := 0
            }
            
            ctrlOpts := "x" x " y" y
            if colW
                ctrlOpts .= " w" colW
            
            x += colW + gap
            maxH := Max(maxH, ctrl.GetHeight())
        }
        return y + maxH
    }
    
    static Section(parent, title, controls, options := {}) {
        ; Create a section with optional GroupBox
        margin := GetOption(options, "Margin", DesignTokens.Space(6))
        spacing := GetOption(options, "Spacing", DesignTokens.Space(3))
        
        y := GetOption(options, "StartY", margin)
        
        if title != "" {
            ; Section title
            parent.SetFont("s14 bold", "Segoe UI Variable")
            titleCtrl := parent.AddText("x" margin " y" y " w0 h0", title)
            y += titleCtrl.GetHeight() + DesignTokens.Space(2)
        }
        
        for ctrl in controls {
            ctrlOpts := "x" margin " y" y
            if HasOption(options, "Width")
                ctrlOpts .= " w" GetOption(options, "Width")
            y += ctrl.GetHeight() + spacing
        }
        
        return y + margin
    }
}

; ============================================================
;  Utility Functions
; ============================================================

Max(a, b) {
    return a > b ? a : b
}

Min(a, b) {
    return a < b ? a : b
}

Clamp(value, min, max) {
    return value < min ? min : (value > max ? max : value)
}

; Color parsing helpers
HexToRGB(hex) {
    hex := StrReplace(hex, "#", "")
    if StrLen(hex) = 3 {
        hex := SubStr(hex,1,1) SubStr(hex,1,1) SubStr(hex,2,1) SubStr(hex,2,1) SubStr(hex,3,1) SubStr(hex,3,1)
    }
    r := "0x" SubStr(hex, 1, 2)
    g := "0x" SubStr(hex, 3, 2)
    b := "0x" SubStr(hex, 5, 2)
    return {r: r, g: g, b: b}
}

RGBToHex(r, g, b) {
    return Format("{:02X}{:02X}{:02X}", r, g, b)
}

; Apply alpha to hex color
ApplyAlpha(hex, alpha) {
    hex := StrReplace(hex, "#", "")
    if StrLen(hex) != 6
        return hex
    alphaHex := Format("{:02X}", Round(alpha * 255))
    return alphaHex . hex
}

; ============================================================
;  System Theme Detection (Singleton)
; ============================================================

class SystemTheme {
    static IsDark := false
    static Callback := 0
    
    static Detect() {
        try {
            val := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme", 1)
            SystemTheme.IsDark := (val = 0)
        } catch {
            SystemTheme.IsDark := false
        }
        DesignTokens.IsDarkMode := SystemTheme.IsDark
        return SystemTheme.IsDark
    }
    
    static Listen() {
        ; Listen for theme changes via registry polling
        if SystemTheme.Callback
            return

        SystemTheme.Callback := SystemTheme.Poll
        SetTimer(SystemTheme.Callback, 2000)
    }

    static Poll() {
        try {
            val := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme", 1)
            newDark := (val = 0)
            if newDark != SystemTheme.IsDark {
                SystemTheme.IsDark := newDark
                DesignTokens.IsDarkMode := newDark
                SystemTheme.OnThemeChange.Call(newDark)
            }
        }
    }
    
    static OnThemeChange := SystemTheme_DefaultHandler
    
    static StopListening() {
        if SystemTheme.Callback
            SetTimer(SystemTheme.Callback, 0)
        SystemTheme.Callback := 0
    }
}

SystemTheme_DefaultHandler(isDark) {
    ; Default handler - windows should override
}
