RunOnStartUp(Yes=1, Name="AHK") {
	If Yes
		FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%\%Name%.lnk, %A_ScriptDir%
	Else
		FileDelete, %A_Startup%\%Name%.lnk
}
