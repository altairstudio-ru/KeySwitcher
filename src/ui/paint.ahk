#Requires AutoHotkey v2.0

; Native controls keep their keyboard behaviour. Only their rendering changes.
class GlassPaint {
    static Items := Map()
    static Windows := Map()
    static Token := 0
    static ToggleProc := 0
    static Toggles := Map()

    static Init() {
        if this.Token
            return
        DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
        input := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
        NumPut("UInt", 1, input)
        token := 0
        if DllCall("gdiplus\GdiplusStartup", "Ptr*", &token, "Ptr", input, "Ptr", 0)
            throw Error("Не удалось запустить отрисовку интерфейса.")
        this.Token := token
        OnMessage(0x2B, ObjBindMethod(GlassPaint, "DrawItem"))
        OnMessage(0x14, ObjBindMethod(GlassPaint, "EraseWindow"))
        ; Keep the GDI+ session for the process lifetime. Shutdown from AHK's
        ; uninterruptible OnExit can deadlock the GDI+ background thread.
        ; Per-window graphics and image handles are released immediately.
    }

    static Attach(ctrl, kind, selected := false) {
        this.Init()
        this.Items[ctrl.Hwnd] := {ctrl: ctrl, kind: kind, selected: selected}
        ctrl.Opt("-Border -E0x200")
        ; Custom-draw keeps the native button type, default action and UIA role.
        ctrl.OnNotify(-12, ObjBindMethod(GlassPaint, "DrawControl"))
        ctrl.OnEvent("Focus", (*) => ctrl.Redraw())
        ctrl.OnEvent("LoseFocus", (*) => ctrl.Redraw())
    }

    static Select(ctrl, selected) {
        if this.Items.Has(ctrl.Hwnd) {
            this.Items[ctrl.Hwnd].selected := selected
            ctrl.Redraw()
        }
    }

    static DrawControl(ctrl, nm, *) {
        if NumGet(nm, A_PtrSize=8 ? 24 : 12, "UInt") != 1
            return 0
        ; Adapt NMCUSTOMDRAW to the common rendering path.
        data := Buffer(A_PtrSize=8 ? 64 : 48,0)
        r := A_PtrSize=8 ? 40 : 20
        state := NumGet(nm,A_PtrSize=8 ? 64 : 40,"UInt")
        NumPut("UInt",state,data,16)
        NumPut("Ptr",ctrl.Hwnd,data,A_PtrSize=8 ? 24 : 20)
        NumPut("Ptr",NumGet(nm,A_PtrSize=8 ? 32 : 16,"Ptr"),data,A_PtrSize=8 ? 32 : 24)
        DllCall("RtlMoveMemory","Ptr",data.Ptr+(A_PtrSize=8 ? 40 : 28),"Ptr",nm+r,"UPtr",16)
        this.DrawItem(0,data.Ptr,0,0)
        return 4
    }

    static Color(name) => Integer("0xFF" DesignTokens.GetTextColor(name, DesignTokens.IsDarkMode))

    static AttachToggle(ctrl) {
        this.Init()
        if !this.ToggleProc
            this.ToggleProc := CallbackCreate(ObjBindMethod(GlassPaint,"ToggleMessage"),,6)
        this.Toggles[ctrl.Hwnd] := ctrl
        DllCall("comctl32\SetWindowSubclass","Ptr",ctrl.Hwnd,"Ptr",this.ToggleProc,"UPtr",1,"UPtr",0)
    }

    static ToggleMessage(hwnd,msg,wp,lp,id,data) {
        if msg = 0x82 {
            DllCall("comctl32\RemoveWindowSubclass","Ptr",hwnd,"Ptr",this.ToggleProc,"UPtr",1)
            if this.Toggles.Has(hwnd)
                this.Toggles.Delete(hwnd)
        } else if msg = 0x14
            return 1
        else if msg = 0xF && this.Toggles.Has(hwnd) {
            ps := Buffer(A_PtrSize=8 ? 72 : 64,0)
            hdc := DllCall("BeginPaint","Ptr",hwnd,"Ptr",ps,"Ptr")
            nm := Buffer(80,0)
            NumPut("UInt",1,nm,A_PtrSize=8 ? 24 : 12)
            NumPut("Ptr",hdc,nm,A_PtrSize=8 ? 32 : 16)
            DllCall("GetClientRect","Ptr",hwnd,"Ptr",nm.Ptr+(A_PtrSize=8 ? 40 : 20))
            try this.DrawToggle(this.Toggles[hwnd],nm.Ptr)
            finally DllCall("EndPaint","Ptr",hwnd,"Ptr",ps)
            return 0
        }
        return DllCall("comctl32\DefSubclassProc","Ptr",hwnd,"UInt",msg,"Ptr",wp,"Ptr",lp,"Ptr")
    }

    static EraseWindow(hdc, lParam, msg, hwnd) {
        if !GlassPaint.Windows.Has(hwnd)
            return
        win := GlassPaint.Windows[hwnd]
        rect := Buffer(16, 0)
        DllCall("GetClientRect", "Ptr", hwnd, "Ptr", rect)
        rgb := GlassPaint.Color("bg-canvas") & 0xFFFFFF
        brush := DllCall("CreateSolidBrush", "UInt", ((rgb&255)<<16)|(rgb&0xFF00)|((rgb>>16)&255), "Ptr")
        DllCall("FillRect", "Ptr", hdc, "Ptr", rect, "Ptr", brush)
        DllCall("DeleteObject", "Ptr", brush)
        if win.BackdropEnabled {
            NumPut("Int", Round(106*A_ScreenDPI/96), rect, 12)
            DllCall("FillRect", "Ptr", hdc, "Ptr", rect, "Ptr", DllCall("GetStockObject", "Int", 4, "Ptr"))
        }
        return 1
    }

    static DrawToggle(ctrl, nm) {
        stage := NumGet(nm, A_PtrSize=8 ? 24 : 12, "UInt")
        if stage != 1
            return 0
        this.Init()
        hdc := NumGet(nm, A_PtrSize=8 ? 32 : 16, "Ptr")
        r := A_PtrSize=8 ? 40 : 20
        x := NumGet(nm,r,"Int"), y := NumGet(nm,r+4,"Int")
        w := NumGet(nm,r+8,"Int")-x, h := NumGet(nm,r+12,"Int")-y
        scale := h/28
        tw := 44*scale, th := 24*scale, tx := x+w-tw-2, ty := y+(h-th)/2
        checked := ctrl.Value
        g := 0
        DllCall("gdiplus\GdipCreateFromHDC", "Ptr", hdc, "Ptr*", &g)
        try {
            DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", g, "Int", 4)
            this.Round(g,x,y,w,h,1,this.Color("bg-canvas"))
            this.Round(g,tx,ty,tw,th,th/2,this.Color(checked ? "toggle-on" : "glass-edge"))
            size := th-4*scale
            kx := checked ? tx+tw-size-2*scale : tx+2*scale
            this.Round(g,kx,ty+2*scale,size,size,size/2,0xFFFFFFFF)
            if DllCall("GetFocus", "Ptr") = ctrl.Hwnd
                this.Round(g,tx-2,ty-2,tw+4,th+4,th/2+2,0,this.Color("accent"))
        } finally DllCall("gdiplus\GdipDeleteGraphics", "Ptr", g)
        DllCall("SetBkMode", "Ptr", hdc, "Int", 1)
        rgb := this.Color(ctrl.Enabled ? "fg-primary" : "fg-tertiary") & 0xFFFFFF
        DllCall("SetTextColor", "Ptr", hdc, "UInt", ((rgb&255)<<16)|(rgb&0xFF00)|((rgb>>16)&255))
        old := DllCall("SelectObject", "Ptr", hdc, "Ptr", SendMessage(0x31,0,0,ctrl.Hwnd), "Ptr")
        rect := Buffer(16,0)
        NumPut("Int",x,"Int",y,"Int",Round(tx-12*scale),"Int",y+h,rect)
        DllCall("DrawText", "Ptr",hdc,"Str",ctrl.Text,"Int",-1,"Ptr",rect,"UInt",0x8824)
        DllCall("SelectObject","Ptr",hdc,"Ptr",old)
        return 4
    }

    static Path(x, y, w, h, radius) {
        path := 0
        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", &path)
        d := Min(radius * 2, Min(w, h))
        for arc in [[x,y,180], [x+w-d,y,270], [x+w-d,y+h-d,0], [x,y+h-d,90]]
            DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", arc[1], "Float", arc[2],
                "Float", d, "Float", d, "Float", arc[3], "Float", 90)
        DllCall("gdiplus\GdipClosePathFigure", "Ptr", path)
        return path
    }

    static Round(g, x, y, w, h, r, fill, border := 0) {
        path := this.Path(x, y, w, h, r)
        brush := 0, pen := 0
        try {
            DllCall("gdiplus\GdipCreateSolidFill", "UInt", fill, "Ptr*", &brush)
            DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", brush, "Ptr", path)
            if border {
                DllCall("gdiplus\GdipCreatePen1", "UInt", border, "Float", 1, "Int", 2, "Ptr*", &pen)
                DllCall("gdiplus\GdipDrawPath", "Ptr", g, "Ptr", pen, "Ptr", path)
            }
        } finally {
            if pen
                DllCall("gdiplus\GdipDeletePen", "Ptr", pen)
            if brush
                DllCall("gdiplus\GdipDeleteBrush", "Ptr", brush)
            DllCall("gdiplus\GdipDeletePath", "Ptr", path)
        }
    }

    static Surface(parent, x, y, w, h, radius := 20, token := "bg-card", text := "", fontSize := 22) {
        this.Init()
        ; Render once at the window DPI; no background polling or animation loop.
        scale := DllCall("GetDeviceCaps", "Ptr", dc := DllCall("GetDC", "Ptr", parent.Hwnd, "Ptr"), "Int", 88) / 96
        DllCall("ReleaseDC", "Ptr", parent.Hwnd, "Ptr", dc)
        pw := Round(w * scale), ph := Round(h * scale)
        bitmap := 0, g := 0, handle := 0
        DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", pw, "Int", ph, "Int", 0,
            "Int", 0x26200A, "Ptr", 0, "Ptr*", &bitmap)
        try {
            DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", bitmap, "Ptr*", &g)
            DllCall("gdiplus\GdipGraphicsClear", "Ptr", g, "UInt", this.Color("bg-canvas"))
            DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", g, "Int", 4)
            this.Round(g, 1, 2, pw-2, ph-3, radius*scale, this.Color(token), this.Color("glass-edge"))
            ; Quiet highlight along the upper edge, independent of text opacity.
            this.Round(g, 8*scale, 3*scale, pw-16*scale, 1.2*scale, scale,
                DesignTokens.IsDarkMode ? 0x22FFFFFF : 0xCCFFFFFF)
            if text != "" {
                family := 0, font := 0, textBrush := 0
                DllCall("gdiplus\GdipCreateFontFamilyFromName","Str","Segoe UI","Ptr",0,"Ptr*",&family)
                DllCall("gdiplus\GdipCreateFont","Ptr",family,"Float",fontSize*scale,"Int",1,"Int",2,"Ptr*",&font)
                DllCall("gdiplus\GdipCreateSolidFill","UInt",this.Color("fg-primary"),"Ptr*",&textBrush)
                rect := Buffer(16,0)
                NumPut("Float",16*scale,"Float",(h-fontSize*1.5)/2*scale,"Float",pw-32*scale,"Float",ph,rect)
                DllCall("gdiplus\GdipSetTextRenderingHint","Ptr",g,"Int",4)
                DllCall("gdiplus\GdipDrawString","Ptr",g,"Str",text,"Int",-1,"Ptr",font,"Ptr",rect,"Ptr",0,"Ptr",textBrush)
                DllCall("gdiplus\GdipDeleteBrush","Ptr",textBrush)
                DllCall("gdiplus\GdipDeleteFont","Ptr",font)
                DllCall("gdiplus\GdipDeleteFontFamily","Ptr",family)
            }
            DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", bitmap, "Ptr*", &handle, "UInt", 0)
        } finally {
            if g
                DllCall("gdiplus\GdipDeleteGraphics", "Ptr", g)
            DllCall("gdiplus\GdipDisposeImage", "Ptr", bitmap)
        }
        ctrl := parent.AddPicture("x" x " y" y " w" w " h" h " +0xE", "HBITMAP:*" handle)
        ; Static bitmaps otherwise expose the internal HBITMAP string to UIA.
        DllCall("SetWindowTextW","Ptr",ctrl.Hwnd,"Str",text)
        ; Clip the bitmap's outer corners so the system material remains
        ; visible around floating surfaces, instead of a rectangular matte.
        rect := Buffer(16,0)
        DllCall("GetClientRect","Ptr",ctrl.Hwnd,"Ptr",rect)
        region := DllCall("CreateRoundRectRgn","Int",0,"Int",0,"Int",NumGet(rect,8,"Int")+1,
            "Int",NumGet(rect,12,"Int")+1,"Int",Round(radius*2*scale),"Int",Round(radius*2*scale),"Ptr")
        if !DllCall("SetWindowRgn","Ptr",ctrl.Hwnd,"Ptr",region,"Int",true)
            DllCall("DeleteObject","Ptr",region)
        ; SS_BITMAP owns the image through AHK; release our original copy.
        DllCall("DeleteObject", "Ptr", handle)
        return ctrl
    }

    static DrawItem(wParam, lParam, msg, hwnd) {
        ctrlHwnd := NumGet(lParam, A_PtrSize = 8 ? 24 : 20, "Ptr")
        if !GlassPaint.Items.Has(ctrlHwnd)
            return
        item := GlassPaint.Items[ctrlHwnd]
        hdc := NumGet(lParam, A_PtrSize = 8 ? 32 : 24, "Ptr")
        off := A_PtrSize = 8 ? 40 : 28
        x := NumGet(lParam, off, "Int"), y := NumGet(lParam, off+4, "Int")
        w := NumGet(lParam, off+8, "Int")-x, h := NumGet(lParam, off+12, "Int")-y
        state := NumGet(lParam, 16, "UInt")
        g := 0
        DllCall("gdiplus\GdipCreateFromHDC", "Ptr", hdc, "Ptr*", &g)
        try {
            DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", g, "Int", 4)
            brush := 0
            DllCall("gdiplus\GdipCreateSolidFill", "UInt", GlassPaint.Color("bg-canvas"), "Ptr*", &brush)
            DllCall("gdiplus\GdipFillRectangle", "Ptr", g, "Ptr", brush, "Float", x-1, "Float", y-1, "Float", w+2, "Float", h+2)
            DllCall("gdiplus\GdipDeleteBrush", "Ptr", brush)
            active := item.kind = "primary" || item.selected
            fill := active ? "accent" : "bg-card"
            if state & 1
                fill := active ? "accent-pressed" : "bg-card-pressed"
            if state & 4
                fill := "bg-card"
            GlassPaint.Round(g, x+1, y+1, w-2, h-2, h/2-1, GlassPaint.Color(fill),
                GlassPaint.Color(active ? "accent" : "glass-edge"))
            if (state & 0x10) && !(state & 0x200)
                GlassPaint.Round(g, x+4, y+4, w-8, h-8, h/2-4, 0,
                    GlassPaint.Color(active ? "fg-on-accent" : "accent"))
        } finally DllCall("gdiplus\GdipDeleteGraphics", "Ptr", g)
        DllCall("SetBkMode", "Ptr", hdc, "Int", 1)
        color := DesignTokens.GetTextColor(state & 4 ? "fg-tertiary" : active ? "fg-on-accent" : "fg-primary", DesignTokens.IsDarkMode)
        rgb := Integer("0x" color)
        DllCall("SetTextColor", "Ptr", hdc, "UInt", ((rgb & 255)<<16) | (rgb & 0xFF00) | ((rgb>>16)&255))
        font := SendMessage(0x31, 0, 0, ctrlHwnd)
        old := DllCall("SelectObject", "Ptr", hdc, "Ptr", font, "Ptr")
        rect := Buffer(16, 0)
        NumPut("Int", x+12, "Int", y, "Int", x+w-12, "Int", y+h, rect)
        DllCall("DrawText", "Ptr", hdc, "Str", item.ctrl.Text, "Int", -1, "Ptr", rect, "UInt", 0x8825)
        DllCall("SelectObject", "Ptr", hdc, "Ptr", old)
        return true
    }

    static Release(gui) {
        if this.Windows.Has(gui.Hwnd)
            this.Windows.Delete(gui.Hwnd)
        for ctrl in gui {
            if this.Items.Has(ctrl.Hwnd)
                this.Items.Delete(ctrl.Hwnd)
        }
    }
}
