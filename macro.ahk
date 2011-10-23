#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent
#SingleInstance, Force
; #NoTrayIcon

SetBatchLines, -1
ListLines, Off
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent  starting directory

global xml, currentXml, version, debug, AhkScript, AhkRecorder, Ini

version := 0.8

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
AhkScript := AhkDllThread(ahkDll)

OnMessage(0x404, "AHK_NOTIFYICON") ; Detect clicks on tray icon
OnMessage(0x4a, "RecieveData")  ; For the recorder script

PID := DllCall("GetCurrentProcessId")
gui := new Main()

if (Ini.Settings.ShowOnStart)
    gui.Show()


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
        AhkScript.ahkFunction("OnEvent", hotkey, "Pressed", A_TimeSinceThisHotkey)

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
            AhkScript.ahkFunction("OnEvent", hotkey, "Down", A_TimeSinceThisHotkey)
        AhkScript.ahkFunction("OnEvent", hotkey, "Released", A_TimeSinceThisHotkey)
    }
Return

WindowActivated( wParam,lParam ) {
    global gui, PID
    ; Check to make sure that profile switching is on
    ; , the current window is not the script , and that the message was for a window being activated.
    if (wParam != 32772 || !Ini.Settings.ProfileSwitching || WinActive("ahk_pid " . PID))
        return
    WinGet, proccessExe, ProcessPath, % "ahk_id " lParam
    debug ? debug(proccessExe . " activated.")
    Loop % A_ScriptDir . "\res\Profiles\*.xml"
    {
        if (A_LoopFileName = "Default.xml")
            Continue
        FileRead, text, % A_LoopFileLongPath
        RegExMatch(text, "`am)\<exe\>(.*)?\<", exe)
        StringSplit, exe, exe1, <
        if (proccessExe = exe1)
        {
            Control, ChooseString, % SubStr(A_LoopFileName, 1, -4),, % "ahk_id " . gui.drpProfiles.hwnd
            switchedProfile := 1
            break
        }
    }
    if (currentXml != A_ScriptDir . "\res\Profiles\Default.xml" && !switchedProfile)
        Control, ChooseString, Default,, % "ahk_id " . gui.drpProfiles.hwnd
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
    text := xml.Get(type, value, "value")

    if (!text)
        return
    else if (type = "macro")
        PlayMacro(value)
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

Test(wParam, lParam) {
    MsgBox, % wParam . "`n" . lParam
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
    if (version >= ver) {
        MsgBox, 64,, You have the latest verison.
        return
    }


    MsgBox, 4, Update, % "Installed Version: " . version . "`nCurrent Version:   " . ver . "`n`nWould you like to update?"
    IfMsgBox, No
        return
    Run % A_ScriptDir . "\res\ahk\updater.exe"
    Exitapp
}

ProcessCommandLine() {
    global debugFile
    Loop, % (arg := {0: %false%}) [0]
    {
        if (%A_Index% == "/install")
            Install()
        else if (%A_Index% = "/debug")
            debug := 1, var := A_Index + 1, debugFile := %var%
    }
}

RecieveData(wParam, lParam)
{
    global gui
    StringAddress := NumGet(lParam + 2*A_PtrSize)  ; Retrieves the CopyDataStruct's lpData member.
    msg := StrGet(StringAddress)  ; Copy the string out of the structure.


    StringSplit, msg, msg, `n
    Loop % msg0 - 1
            gui.Macro.currentMacro.Items.Add("", msg%A_Index%) ; Add the key to listview.
    Rows := gui.Macro.currentMacro.Items.Count
    gui.Macro.currentMacro.Items.Modify(rows, "vis") ; Makes sure the added key is visible.

    return true  ; Returning 1 (true) is the traditional way to acknowledge this message.
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
