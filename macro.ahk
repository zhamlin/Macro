#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent
#SingleInstance, Force
; #NoTrayIcon

SetBatchLines, -1
ListLines, Off
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory

global xml, currentXml, version, debug, AhkScript, Ini, debugFile

version := 0.7

ProcessCommandLine()

if (!FileExist(A_ScriptDir . "\res"))
    Install()

if (Ini.UpdateOnStart)
    Update()

currentXml := A_ScriptDir . "\res\Profiles\Default.xml"
xml := new Xml(currentXml)
xml.Save(currentXml)

Ini := new Ini(A_ScriptDir . "\res\settings.ini")
ahkDll := A_ScriptDir . "\res\dll\AutoHotkey.dll"

AhkRecorder := AhkDllThread(ahkDll)
AhkSender := AhkDllThread(ahkDll)
AhkScript := AhkDllThread(ahkDll)
AhkSender.ahkTextDll("")

OnMessage(0x404, "AHK_NOTIFYICON") ; Detect clicks on tray icon

PID := DllCall("GetCurrentProcessId")
gui := new Main()

DllCall( "RegisterShellHookWindow", UInt, gui.hwnd )
MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )
OnMessage( MsgNum, "WindowActivated" )
return

Pressed:
    hotkey := Trim(RegExReplace(A_ThisHotkey, "([\$\*\<\>\~\#\!\^\+]|(?<!_)Up)"))
    debug ? debug(hotkey . " pressed")

    ; get all the info for the hotkey
    type := xml.Get("key", hotkey, "type")
    value := xml.Get("key", hotkey, "value")
    repeat := xml.Get("key", hotkey, "repeat")


    if (type = "textblock")
        delay := xml.Get("textblock", value, "delay")
    else if (type = "script")
        AhkScript.ahkFunction("OnEvent", hotkey, "Pressed", A_TimeSinceThisHotkey, currentXml)

    if (repeat = "toggle")
    {
        toggle := !toggle
        if (!toggle)
            return
        while (toggle)
        {
            sleep, 10
            HandleKey(type, value, delay)
        }
        toggle := false
        return
    }
    else if (type != "script")
        HandleKey(type, value, delay)

    if (type != "script" && repeat = "None")
        KeyWait % Hotkey
    else if (type = "script")
    {
        While (GetKeyState(hotkey, "P") )
            AhkScript.ahkFunction("OnEvent", hotkey, "Down", A_TimeSinceThisHotkey, currentXml)
        AhkScript.ahkFunction("OnEvent", hotkey, "Released", A_TimeSinceThisHotkey, currentXml)
    }
Return

WindowActivated( wParam,lParam ) {
    global PID, gui
    ; Check to make sure that profile switching is on
    ; , the current window is not the script , and that the message was for a window being activated.
    if (wParam != 32772 || !Ini.Settings.ProfileSwitching || WinActive("ahk_pid " . PID))
        return
    WinGet, proccessExe, ProcessPath, % "ahk_id " lParam
    debug ? debug("Checking for different profile.")
    Loop % A_ScriptDir . "\res\Profiles\*.xml"
    {
        if (A_LoopFileName = "Default.xml")
            Continue
        FileRead, text, % A_LoopFileLongPath
        RegExMatch(text, "`am)\<exe\>(.*)?\<", exe)

        if (proccessExe = exe1)
        {
            Control, ChooseString, % SubStr(A_LoopFileName, 1, -4), % gui.drpProfiles.ClassNN, % "ahk_id " . gui.hwnd
            switchedProfile := 1
            break
        }
    }
    if (currentXml != A_ScriptDir . "\res\Profiles\Default.xml" && !switchedProfile)
        Control, ChooseString, Default, % gui.drpProfiles.ClassNN, % "ahk_id " . gui.hwnd
    switchedProfile := 0
}


Hotkeys(disable = 0) {
    debug ? debug("Turning " . (disable ? "off" : "on") . " hotkeys")
    keys := xml.List("keys", "|")
    Loop, Parse, keys, |
        if (A_LoopField)
        {
            ; Turn (on|off) the key
            options := xml.GetAttribute(A_LoopField)
            repeat := xml.Get("key", hotkey, "repeat")
            Hotkey, % "$" . options, % (disable ? "Off" : "Pressed"), % (disable ? "Off" : "On T" . ((repeat = "toggle") + 1))
        }
}

HandleKey(type, value, delay = -1) {
    global AhkSender
    text := xml.Get(type, value, "value")

    if (!text)
        return
    else if (type = "macro")
    {
        if (InStr(text, "Sleep"))
        {
            text := RegExReplace(text, "(\{\w*?\s(?:Down|Up)\})", "Send, $1")
            StringReplace, text, text, ``n, `n, all
        }
        else
        {
            text := "Send, " . text
            StringReplace, text, text, ``n, , all
        }
        AhkSender.ahkExec(text) ; Send macro in a new thread.
    }
    else if (type = "textblock")
    {
        StringReplace, text, text, ``n, `n, all
        SetKeyDelay % delay
        SendRaw % text
        SetKeyDelay, -1
    }
}

GetProfiles() {
    Loop, % A_ScriptDir . "\res\Profiles\*.xml"
        profiles .= A_LoopFileName . "|"
    return profiles
}


AHK_NOTIFYICON(wParam, lParam) {
    global gui
    if lParam = 0x201 ; WM_LBUTTONUP
        return
    else if lParam = 0x203 ; WM_LBUTTONDBLCLK
        gui.Show()

}

Install() {
    debug ? debug("Installing files")

    ; Small delay so the updater can exit
    Sleep, 1000
    FileCreateDir, % A_ScriptDir . "\res"
    FileCreateDir, % A_ScriptDir . "\res\ahk"
    FileCreateDir, % A_ScriptDir . "\res\dll"
    FileCreateDir, % A_ScriptDir . "\res\profiles"

    FileInstall, res\dll\AutoHotkey.dll, res\dll\AutoHotkey.dll, 1
    FileInstall, res\dll\SciLexer.dll, res\dll\SciLexer.dll, 1
    FileInstall, res\ahk\updater.exe, res\ahk\updater.exe, 1
    FileInstall, res\ahk\Recorder.ahk, res\ahk\Recorder.ahk, 1
}

Update() {
    if (!A_IsCompiled)
        return

    UrlDownloadToFile, http://www.autohotkey.net/~zzzooo11/Macro/version.txt, % A_ScriptDir . "\v.txt"
    FileRead, ver, % A_ScriptDir . "\v.txt"
    FileDelete, % A_ScriptDir . "\v.txt"

    ; We have the latest verion
    if (version = ver)
        return

    MsgBox, 4, Update, % "Installed Version: " . version . "`nCurrent Version:   " . ver . "`n`nWould you like to update?"
    IfMsgBox, No
        return
    Run % A_ScriptDir . "\res\ahk\updater.exe"
    Exitapp
}

ProcessCommandLine() {
    Loop, % (arg := {0: %false%}) [0]
    {
        if (%A_Index% == "/install")
            Install()
        else if (%A_Index% = "/debug")
            debug := 1, var := A_Index + 1, debugFile := %var%
    }
}

#include <CGUI>
#include <Xml>
#include <ini>
#include <Debug>

#Include, %A_ScriptDir%\res\ahk\macro_recorder.ahk
#Include, %A_ScriptDir%\res\ahk\profile_settings.ahk
#Include, %A_ScriptDir%\res\ahk\textBlock.ahk
#Include, %A_ScriptDir%\res\ahk\settings.ahk
#Include, %A_ScriptDir%\res\ahk\main.ahk
#Include, %A_ScriptDir%\res\ahk\settings.ahk
#Include, %A_ScriptDir%\res\ahk\windows.ahk
