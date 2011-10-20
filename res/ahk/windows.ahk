class Windows extends CGUI
{

	__New(mainGui, Owner)
	{
		this.windowsLV := this.AddControl("ListView", "windowsLV", "w500 h300 NoSortHdr -Multi -LV0x10", "Title                               |Class                     |Exe")
		this.windowsLV.IndependentSorting := true
		this.AddControl("Button", "btnCancel", "x435 w75 h23", "Cancel")

		this.Title := "Select Program"
        this.gui   := mainGui
        this.Owner := owner, this.OwnerAutoClose := 1, this.MinimizeBox := 0
	}

	Load() {
		this.AddWindows()
		this.Show()
		this.windowsLV.Modify()
	}

	windowsLV_DoubleClick(RowItem) {
		class := this.windowsLV.Items[RowItem][2]
		; No item was selected
		if (!class)
			return
		WinGet, exe, ProcessPath, % "ahk_class " . class
		this.gui.Profile.edtExe.Text := exe
		this.btnCancel_Click()
	}

	AddWindows() {
		windows := GetWindows()
		for index, window in windows
		{
			for key, value in window
				%key% := value
			this.windowsLV.Items.Add("", title, class, exe)
		}
	}

	btnCancel_Click() {
		this.gui.Profile.Enabled := true
		this.Hide()
        Loop % this.windowsLV.Items.Count
            this.windowsLV.Items.Delete(1)
	}

	PreClose() {
		this.gui.Profile.Enabled := true
	}

}

GetWindows() {
	DetectHiddenWindows, Off
	WinGet, id, list,,, Program Manager
	Windows := []
	Loop % id
	{
		id := id%A_Index%
		WinGetClass, class, ahk_id %id%
		WinGet, exe, ProcessName, ahk_id %id%
		WinGetTitle, title, ahk_id %id%
		if((!title && exe != "Explorer.exe") ||  InStr(class, "Tooltip") || InStr(class, "SysShadow")) ;Filter some windows
			continue
		tmpArray := { title: title, class: class, exe: exe}
		Windows.Insert(tmpArray)
	}
	return Windows
}
