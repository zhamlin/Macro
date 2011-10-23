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
    if hotkey in %mouseButtons%
    {
        if (location)
        {
            MouseGetPos, x, y
            Send("MouseMove, " . x . ", " . y . "`n")
        }
    }
    msg := "{" . Hotkey . " Down}`n", Send(msg)
    KeyWait % Hotkey
    msg := ( (delay ? ("Sleep, " . (done ? A_TimeSincePriorHotkey - A_TimeSinceThisHotkey -30 : A_TimeSinceThisHotkey - 30) . "`n") : "")
        . "{" . (done ? A_PriorHotkey : Hotkey) . " Up}`n" )
    Send(msg)

    done := 1
return


Send(ByRef StringToSend)  ; ByRef saves a little memory in this case.
; This function sends the specified string to the specified window and returns the reply.
; The reply is 1 if the target window processed the message, or 0 if it ignored it.
{
    global PID
    VarSetCapacity(CopyDataStruct, 3*A_PtrSize, 0)  ; Set up the structure's memory area.
    ; First set the structure's cbData member to the size of the string, including its zero terminator:
    SizeInBytes := (StrLen(StringToSend) + 1) * (A_IsUnicode ? 2 : 1)
    NumPut(SizeInBytes, CopyDataStruct, A_PtrSize)  ; OS requires that this be done.
    NumPut(&StringToSend, CopyDataStruct, 2*A_PtrSize)  ; Set lpData to point to the string itself.

    SendMessage, 0x4a, 0, &CopyDataStruct,, ahk_pid %PID%  ; 0x4a is WM_COPYDATA. Must use Send not Post.
    return ErrorLevel  ; Return SendMessage's reply back to our caller.
}
