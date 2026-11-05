#Requires AutoHotkey v2.0
; ============================================================
;  ui/tokens.ahk  —  Design Tokens for AltaiR Key Switcher
;  Windows 11 Fluent + iOS 26 Glassmorphism design system
; ============================================================

Tokens := {}

; ---- Color Tokens (Light Mode) ----
Tokens.Light := Map(
    "bg-canvas",       "F3F4F8",      ; Window background (Mica base)
    "bg-card",         "FFFFFFFF",    ; Glass panel fill
    "bg-card-hover",   "FFFFFFFF",    ; Hover state
    "bg-card-pressed", "FFFFFFFF",    ; Active/pressed
    "accent",          "0067C0",      ; Primary blue
    "accent-hover",    "0052A3",
    "accent-pressed",  "004180",
    "accent-glow",     "0067C0",      ; Focus ring color
    "fg-primary",      "101828",      ; Headings, primary text
    "fg-secondary",    "475467",      ; Body text
    "fg-tertiary",     "667085",      ; Captions, disabled
    "fg-on-accent",    "FFFFFF",      ; Text on accent
    "border-subtle",   "101828",      ; Glass borders
    "border-focus",    "0067C0",      ; Focus indicators
    "divider",         "101828",      ; Section dividers
    "shadow-xs",       "0D101828",    ; 0 1px 2px rgba(16,24,40,0.05)
    "shadow-sm",       "14101828",    ; 0 2px 8px rgba(16,24,40,0.08)
    "shadow-md",       "1F101828",    ; 0 8px 24px rgba(16,24,40,0.12)
    "shadow-glow",     "2E0067C0"     ; 0 0 0 3px rgba(0,103,192,0.18)
)

; ---- Color Tokens (Dark Mode) ----
Tokens.Dark := Map(
    "bg-canvas",       "101828",
    "bg-card",         "FF161C28",    ; Glass panel fill
    "bg-card-hover",   "FF161C28",
    "bg-card-pressed", "FF161C28",
    "accent",          "3B82F6",      ; Lighter blue for dark mode
    "accent-hover",    "60A5FA",
    "accent-pressed",  "2563EB",
    "accent-glow",     "3B82F6",
    "fg-primary",      "F2F4F7",
    "fg-secondary",    "D0D5DD",
    "fg-tertiary",     "98A2B3",
    "fg-on-accent",    "FFFFFF",
    "border-subtle",   "F2F4F7",
    "border-focus",    "3B82F6",
    "divider",         "F2F4F7",
    "shadow-xs",       "4D000000",    ; 0 1px 2px rgba(0,0,0,0.30)
    "shadow-sm",       "66000000",    ; 0 2px 8px rgba(0,0,0,0.40)
    "shadow-md",       "80000000",    ; 0 8px 24px rgba(0,0,0,0.50)
    "shadow-glow",     "403B82F6"     ; 0 0 0 3px rgba(59,130,246,0.25)
)

; ---- Semantic Alpha Values (applied at runtime) ----
Tokens.Alpha := Map(
    "bg-card",         0.72,          ; 72% opacity for glass
    "bg-card-hover",   0.88,
    "bg-card-pressed", 0.60,
    "border-subtle",   0.08,
    "border-hover",    0.16,
    "divider",         0.06,
    "shadow-xs",       0.05,
    "shadow-sm",       0.08,
    "shadow-md",       0.12,
    "shadow-glow",     0.18
)

; ---- Dark Mode Alpha Overrides ----
Tokens.AlphaDark := Map(
    "bg-card",         0.72,
    "bg-card-hover",   0.88,
    "bg-card-pressed", 0.60,
    "border-subtle",   0.12,
    "border-hover",    0.20,
    "divider",         0.08,
    "shadow-xs",       0.30,
    "shadow-sm",       0.40,
    "shadow-md",       0.50,
    "shadow-glow",     0.25
)

; ---- Spacing Tokens (4px base unit) ----
Tokens.Space := Map(
    1, 4,   2, 8,   3, 12,  4, 16,  5, 20,
    6, 24,  7, 28,  8, 32,  9, 36,  10, 40,
    11, 44, 12, 48, 13, 52, 14, 56, 15, 60,
    16, 64
)

; ---- Border Radius Tokens ----
Tokens.Radius := Map(
    "xs", 4, "sm", 8, "md", 12, "lg", 16, "xl", 24, "full", 9999
)

; ---- Typography Tokens ----
Tokens.Typography := Map(
    "font-family",        "Segoe UI Variable",
    "font-family-fb",     "Segoe UI",        ; Fallback
    "font-family-mono",   "Cascadia Mono",   ; For hotkeys
    "font-family-mono-fb", "Consolas",       ; Fallback
    ; Scale: size, weight, line-height, letter-spacing
    "display",   { size: 28, weight: 600, lineHeight: 36, letterSpacing: -0.02 },
    "title",     { size: 20, weight: 600, lineHeight: 28, letterSpacing: -0.01 },
    "heading",   { size: 16, weight: 600, lineHeight: 24, letterSpacing: 0 },
    "body",      { size: 14, weight: 400, lineHeight: 20, letterSpacing: 0 },
    "body-s",    { size: 14, weight: 500, lineHeight: 20, letterSpacing: 0 },
    "caption",   { size: 12, weight: 400, lineHeight: 16, letterSpacing: 0.01 },
    "caption-s", { size: 12, weight: 500, lineHeight: 16, letterSpacing: 0.01 },
    "mono",      { size: 13, weight: 500, lineHeight: 20, letterSpacing: 0.02 }
)

; ---- Motion Tokens ----
Tokens.Motion := Map(
    "instant", { duration: 0,   easing: "linear" },
    "fast",    { duration: 120, easing: "cubic-bezier(0.2, 0, 0.38, 0.9)" },
    "normal",  { duration: 200, easing: "cubic-bezier(0.2, 0, 0.38, 0.9)" },
    "slow",    { duration: 320, easing: "cubic-bezier(0.2, 0, 0.38, 0.9)" },
    "spring",  { duration: 400, easing: "cubic-bezier(0.34, 1.56, 0.64, 1)" }
)

; ---- Component Sizing Tokens ----
Tokens.Sizing := Map(
    "button-height",     40,
    "button-height-sm",  32,
    "input-height",      36,
    "toggle-width",      44,
    "toggle-height",     24,
    "toggle-thumb",      20,
    "slider-height",     4,
    "slider-thumb",      16,
    "toast-max-width",   360,
    "tray-min-width",    220,
    "tray-item-height",  36,
    "icon-sm",           16,
    "icon-md",           20,
    "icon-lg",           24,
    "logo-size",         56
)

; ---- Breakpoints ----
Tokens.Breakpoints := Map(
    "mobile", 640, "tablet", 768, "desktop", 1024, "wide", 1280
)

; ---- Z-Index Scale ----
Tokens.ZIndex := Map(
    "base", 0, "card", 10, "dropdown", 100, "modal", 200,
    "toast", 300, "tooltip", 400, "tray", 500
)

; ---- Helper: Get token with theme ----
GetToken(tokenPath, isDark := false) {
    theme := isDark ? Tokens.Dark : Tokens.Light
    ; Support dot notation: "fg.primary" -> "fg-primary"
    key := StrReplace(tokenPath, ".", "-")
    if theme.Has(key)
        return theme[key]
    if Tokens.Space.Has(key)
        return Tokens.Space[key]
    if Tokens.Radius.Has(key)
        return Tokens.Radius[key]
    if Tokens.Sizing.Has(key)
        return Tokens.Sizing[key]
    return ""
}

; ---- Helper: Get color with alpha applied ----
GetColor(tokenName, isDark := false, customAlpha := "") {
    theme := isDark ? Tokens.Dark : Tokens.Light
    alphaMap := isDark ? Tokens.AlphaDark : Tokens.Alpha

    if !theme.Has(tokenName)
        return ""
    hex := theme[tokenName]

    ; If 8-char hex (includes alpha), return as-is
    if StrLen(hex) = 8
        return hex

    alpha := customAlpha != "" ? customAlpha : (alphaMap.Has(tokenName) ? alphaMap[tokenName] : 1.0)
    alphaHex := Format("{:02X}", Round(alpha * 255))
    return alphaHex . hex
}

; ---- Helper: Get text color (always 6-char RRGGBB, no alpha) ----
GetTextColor(tokenName, isDark := false) {
    theme := isDark ? Tokens.Dark : Tokens.Light
    if !theme.Has(tokenName)
        return ""
    hex := theme[tokenName]
    if StrLen(hex) = 8
        return SubStr(hex, 3)
    return hex
}

; ---- Helper: Get spacing ----
SpaceHelper(n) {
    return Tokens.Space.Has(n) ? Tokens.Space[n] : (n * 4)
}

; ---- Helper: Get radius ----
RadiusHelper(name) {
    return Tokens.Radius.Has(name) ? Tokens.Radius[name] : Tokens.Radius["md"]
}

; ---- Helper: Get typography ----
TypographyHelper(role) {
    return Tokens.Typography.Has(role) ? Tokens.Typography[role] : Tokens.Typography["body"]
}

; ---- Helper: Get motion ----
MotionHelper(name) {
    return Tokens.Motion.Has(name) ? Tokens.Motion[name] : Tokens.Motion["normal"]
}

; ---- Export ----
class DesignTokens {
    static IsDarkMode := false

    static Sizing => Tokens.Sizing

    static GetToken(tokenPath, isDark := false)      => GetToken(tokenPath, isDark)
    static GetColor(tokenName, isDark := false, customAlpha := "") => GetColor(tokenName, isDark, customAlpha)
    static GetTextColor(tokenName, isDark := false)  => GetTextColor(tokenName, isDark)
    static Space(n)       => SpaceHelper(n)
    static Radius(name)   => RadiusHelper(name)
    static Typography(role) => TypographyHelper(role)
    static Motion(name)   => MotionHelper(name)

    static DetectSystemTheme() {
        val := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme", 1)
        DesignTokens.IsDarkMode := (val = 0)
        return DesignTokens.IsDarkMode
    }

    static ToggleTheme() {
        DesignTokens.IsDarkMode := !DesignTokens.IsDarkMode
    }
}
