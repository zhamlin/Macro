#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent
#SingleInstance, Force
#NoTrayIcon

SetBatchLines, -1
ListLines, Off
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

EndKeys := "
( LTrim
    LWin RWin AppsKey
    LShift RShift LControl RControl LAlt RAlt
    F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12
    Left Right Up Down
    Insert Delete Home End PgUp PgDn
    Space Tab Enter Escape Backspace
    CapsLock NumLock ScrollLock
    PrintScreen Pause
    Numpad0 Numpad1 Numpad2 Numpad3 Numpad4
    Numpad5 Numpad6 Numpad7 Numpad8 Numpad9
    NumpadIns NumpadEnd NumpadDown NumpadPgDn NumpadLeft
    NumpadClear NumpadRight NumpadHome NumpadUp NumpadPgUp
    NumpadDot NumpadDel
    NumpadDiv NumpadMult NumpadSub NumpadAdd NumpadEnter
)"
StringReplace, endKeys, endKeys, `n, %A_Space%, All
keys := "qwertyuiopasdfghjklzxcvbnm1234567890-=[]\;',./"
mouseButtons := "RButton,LButton,MButton"

Loop, Parse, keys
    Hotkey, % A_LoopField, Keys
Loop, Parse, EndKeys, %A_Space%
    Hotkey, % A_LoopField, Keys

if (mouseClicks)
    Loop, Parse, mouseButtons, `,
        Hotkey, % "~" . A_LoopField, Keys
return

Keys:
    StringReplace, Hotkey, A_ThisHotkey, ~
    done := 0

    msg := "{" . Hotkey . " Down}`n"
    KeyWait % Hotkey
    msg := ( (delay ? ("Sleep, " . (done ? A_TimeSincePriorHotkey - A_TimeSinceThisHotkey : A_TimeSinceThisHotkey) . "`n") : "")
        . "{" . (done ? A_PriorHotkey : Hotkey) . " Up}`n" )

    done := 1
    Sleep, 10
return
