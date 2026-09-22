#Requires AutoHotkey v2.0
; Головная самопроверка карты раскладок: пишет результат в файл.
#Include "..\layout-map.ahk"
pairs := 0, fail := 0
SelfTest(&pairs, &fail)
out := A_ScriptDir "\selftest.txt"
FileDelete(out)
FileAppend("pairs=" pairs " fail=" fail, out)
ExitApp()
