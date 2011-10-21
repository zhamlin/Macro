url      := "http://www.autohotkey.net/~zzzooo11/Macro/macro.exe"
baseDir  := SubStr(A_ScriptDir, 1, -7)
fileName := "macro.exe"

Download(url, baseDir . fileName)
Run % baseDir . fileName " /install"
Exitapp


; Based on code by Sean and SKAN @ http://www.autohotkey.com/forum/viewtopic.php?p=184468#184468
Download(url, file)
{
    static vt
    if !VarSetCapacity(vt)
    {
        VarSetCapacity(vt, A_PtrSize*11), nPar := "31132253353"
        Loop Parse, nPar
            NumPut(RegisterCallback("DL_Progress", "F", A_LoopField, A_Index-1), vt, A_PtrSize*(A_Index-1))
    }
    global _cu
    SplitPath file, dFile
    SysGet m, MonitorWorkArea, 1
    y := mBottom-52-2, x := mRight-330-2, VarSetCapacity(_cu, 100)
    , DllCall("shlwapi\PathCompactPathEx", "str", _cu, "str", url, "uint", 50, "uint", 0)
    Progress Hide CWFAFAF7 CT000020 CB445566 x%x% y%y% w330 h52 B1 FS8 WM700 WS700 FM8 ZH12 ZY3 C11,, %_cu%, AutoHotkeyProgress, Tahoma
    WinSet Transparent, 192, AutoHotkeyProgress
    re := DllCall("urlmon\URLDownloadToFile", "ptr", 0, "str", url, "str", file, "uint", 0, "ptr*", &vt)
    Progress Off
    return re=0 ? 1 : 0
}
DL_Progress( pthis, nP=0, nPMax=0, nSC=0, pST=0 )
{
    global _cu
    if A_EventInfo = 6
    {
        Progress Show
        Progress % P := 100*nP//nPMax, % "Downloading:     " Round(np/1024,1) " KB / " Round(npmax/1024) " KB    [ " P "`% ]", %_cu%
    }
    return 0
}
