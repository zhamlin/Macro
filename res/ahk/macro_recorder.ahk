Class MacroRecorder Extends CGUI
{

	__New(mainGui, owner = "")
    {
		this.btnAdd := this.AddControl("Button", "btnAdd", "x20 y380 w90 h23", "New")
        this.btnCancel := this.AddControl("Button", "btnCancel", "x462 y400 w90 h23", "Cancel")
        this.btnDelete := this.AddControl("Button", "btnDelete", "x110 y380 w90 h23", "Delete")
        this.btnOK := this.AddControl("Button", "btnOK", "x362 y400 w90 h23", "OK")
        this.btnHelp := this.AddControl("Button", "btnHelp", "x562 y400 w90 h23", "Help")

        this.btnStartRecord := this.AddControl("Button", "btnStartRecord", "x525 y50 w90 h23", "Start Recording")
        this.btnStopRecord := this.AddControl("Button", "btnStopRecord", "x525 y25 w90 h23", "Stop Recording")

        this.chkDelay := this.AddControl("Checkbox", "chkDelay", "x485 y80 w165 h30", "Record delays between events")
        this.chkMouse := this.AddControl("Checkbox", "chkMouse", "x485 y110 w165 h30", "Include mouse clicks")

		this.AddControl("GroupBox", "e", "x222 y10 w430 h380", "Details")

        this.macroList := this.AddControl("ListView", "macroList", "x12 y10 w190 h360 NoSortHdr -Multi -ReadOnly", "Macro")
        this.currentMacro := this.AddControl("ListView", "currentMacro", "x232 y40 w250 h330 NoSortHdr -Multi count100", "Keys")

        this.btnStopRecord.Disable()
        this.btnStartRecord.Disable()


        Menu, MacroName, Add, Edit, EditName
        Menu, MacroName, Add, Delete, DeleteName

        Menu, LButton, Add, Down, MouseEvent
        Menu, LButton, Add, Up, MouseEvent
        Menu, LButton, Add, Click, MouseEvent

        Menu, RButton, Add, Down, MouseEvent
        Menu, RButton, Add, Up, MouseEvent
        Menu, RButton, Add, Click, MouseEvent

        Menu, MButton, Add, Down, MouseEvent
        Menu, MButton, Add, Up, MouseEvent
        Menu, MButton, Add, Click, MouseEvent

        Menu, Wheel, Add, Backward, MouseEvent
        Menu, Wheel, Add, Forward, MouseEvent

        Menu, MouseEvents, Add, Left Button, :LButton
        Menu, MouseEvents, Add, Right Button, :RButton
        Menu, MouseEvents, Add, Middle Button, :MButton
        Menu, MouseEvents, Add, Wheel, :Wheel

        Menu, Macro, Add, Insert Mouse Event, :MouseEvents, P100

        Menu, Macro, Add, Edit, Edit
        Menu, Macro, Add, Insert Delay, InsertDelay
        Menu, Macro, Add, Delete, Delete ; Menu for adding delays and mouse events

        this.gui := mainGui
        if (owner)
            this.Owner := owner, this.OwnerAutoClose := 1, this.MinimizeBox := 0

        this.Toolwindow := 1
		this.Title := "Macro Recorder"
	}

    btnOK_Click()
    {
        debug ? debug("Saving macros")
        this.UpdateMacro()
        xml.Save(A_ScriptDir . "\res\Profiles\" . xml.Get("name") . ".xml") ; Save xml file.
        this.ClearCurrentMacro()

        ; Update current hotkey with new macro name.
        if (this.selectedRow)
            if (macroName := this.MacroName(this.selectedRow))
                this.gui.UpdateKey(MacroName)

        this.oldMacroName := "", this.selectedRow := 0
        this.gui.Enabled := true
        this.Hide()
        this.gui.UpdateMacros()
    }

    btnHelp_Click()
    {
        MsgBox,
        ( LTrim
            Right click "Keys" listview for context menu.

            Any thing selected from context menu will be added to bottom of seleced item.
        )
    }

    btnStartRecord_Click()
	{
        global globalDelay, globalClick
        this.StopRecording := 0
        this.ClearCurrentMacro()

        debug ? debug("Start recording macro")

        ; Disable controls while recording keys.
        this.SetControls(0)
        this.btnStopRecord.Enabled  := 1
        this.btnStartRecord.Enabled := 0

        globalDelay := this.chkDelay.Checked
        globalClick := this.chkMouse.Checked
        SetTimer, record, 1
	}


    btnStopRecord_Click()
    {
        debug ? debug("Stop recording macro")
        this.StopRecording := 1
        ; Enable controls
        this.SetControls(1)
        this.btnStopRecord.Enabled  := 0
        this.btnStartRecord.Enabled := 1
        this.UpdateMacro()
    }

    SetControls(Enabled)
    {
        this.currentMacro.Enabled   := Enabled
        this.macroList.Enabled      := Enabled
        this.btnOK.Enabled          := Enabled
        this.btnAdd.Enabled         := Enabled
        this.btnDelete.Enabled      := Enabled
        this.chkDelay.Enabled       := Enabled
        this.chkMouse.Enabled       := Enabled
    }

    btnCancel_Click()
    {
        debug ? debug("Canceled macro manager")
        this.PreClose()
        this.Hide()
    }

	btnAdd_Click(saveRow = 0)
	{
        debug ? debug("Added macro")
        Loop ; Create a macro with a unique name.
        {
            macroName := "Macro" . A_Index
            if (!xml.Exist("macro", macroName))
                break
        }
		this.macroList.Items.Add("Select", macroName)
        this.macroList.Items.Modify(this.macroList.Items.Count, "vis")
        xml.AddMacro(macroName, "")

        ; Make the name editable right away.
        ControlFocus, SysListView321, A
        ControlSend, SysListView321, {End}, A
        ControlSend, SysListView321, {F2}, A

        ; Save current macro for possible use.
        if (saveRow)
            this.selectedRow := this.macroList.FocusedIndex
	}

    btnDelete_Click()
    {
        selectedRow := this.macroList.FocusedIndex
        if (!text := this.macroList.Items[selectedRow][1])
            return
        MsgBox, 52, , % "Are you sure you want to delete:`n" . text
        IfMsgBox, No
            return
        debug ? debug("Deleted macro: " . text)
        this.macroList.Items.Delete(selectedRow)
        this.ClearCurrentMacro()
        xml.Delete("macros", text)
    }

    currentMacro_ContextMenu()
    {
        if (this.macroList.FocusedIndex && this.currentMacro.Enabled) ;Also works if other controls like the button were focused before.
        {
            selectedRow := this.currentMacro.FocusedIndex
            ControlGet, pressedKeys, List, , % this.currentMacro.ClassNN, A ; Get all the keys from the listbox
            StringSplit, text,pressedKeys, `n

            if (InStr(text%selectedRow%, "Sleep"))
            {
                Menu, Macro, Enable, Edit
                GuiControl, -ReadOnly, % this.currentMacro.ClassNN
            }
            else
                Menu, Macro, Disable, Edit
            Menu, Macro, Show
        }
    }

    macroList_ContextMenu()
    {
        if (this.macroList.FocusedIndex && this.macroList.Enabled)
            Menu, MacroName, Show
    }

    MacroName(Index)
    {
        ControlGet, macros, List, , % this.macroList.ClassNN, A ; Get all the keys from the listbox
        StringSplit, macroName, macros, `n
        return macroName%Index%
    }

    macroList_ItemFocused(RowIndex)
    {
        macroName := this.MacroName(RowIndex)

        if (macroName = this.oldMacroName)
            return
        else if macroName is number
            return

        this.oldMacroName := macroName
        this.LoadMacro(macroName) ; Update ListView to show keys in macro
        debug ? debug("Loaded macro: " . macroName)
    }


    macroList_EditingStart(RowIndex)
    {
        this.savedText := this.macroList.Items[RowIndex][1]
    }

    macroList_EditingEnd(RowIndex)
    {
        text := this.macroList.Items[RowIndex][1]
        firstChar := SubStr(text, 1, 1)

        ; Make sure name is fine
        if text is not alnum
        {
            MsgBox, 48, , Only letters and numbers allowed.
            this.macroList.Items[RowIndex][1] := this.savedText
        }
        else if (!text) ; Make sure text isn't blank
            this.macroList.Items[RowIndex][1] := this.savedText
        else if firstChar is not Alpha
        {
            MsgBox, 48, , Macro names must start with a letter.
            this.macroList.Items[RowIndex][1] := this.savedText
        }
        else if (text = this.savedText)
            return
        else if (xml.Exist("macro", text)) ; Check to make sure we don't have duplicate macros.
        {
            MsgBox, 48, ,Duplicate names are not allowed.
            this.macroList.Items[RowIndex][1] := this.savedText
        }
        else
        {
            xml.Rename("macro", this.savedText, text)
            debug ? debug("Renamed macro: " . this.savedText . " to " . text)
            ; xml.Save(A_ScriptDir, xml.Get("name")) ; Save xml file.
        }
    }

    currentMacro_EditingStart(RowIndex)
    {
        selectedRow := this.currentMacro.FocusedIndex
        ControlGet, pressedKeys, List, , % this.currentMacro.ClassNN, A ; Get all the keys from the listbox
        StringSplit, text,pressedKeys, `n
        text := text%selectedRow%

        if (!InStr(text, "Sleep"))
        {
            GuiControl, +ReadOnly, % this.currentMacro.ClassNN
            return
        }
        this.savedDelay := text
        Send % Trim(RegExReplace(text, "Sleep??,[\s]*?")) . "^+{Left}"
    }

    currentMacro_EditingEnd(RowIndex)
    {
        ControlGet, pressedKeys, List, , % this.currentMacro.ClassNN, A ; Get all the keys from the listbox
        StringSplit, text, pressedKeys, `n
        text := text%RowIndex%

        if (!text)
            this.currentMacro.Items.Modify(RowIndex, "", this.savedDelay)
        else if text is not number
            this.currentMacro.Items.Modify(RowIndex, "", this.savedDelay)
        else
            this.currentMacro.Items.Modify(RowIndex, "", "Sleep, " . text)

    }

    ClearCurrentMacro()
    {
        Loop % this.currentMacro.Items.Count
            this.currentMacro.Items.Delete(1)
    }

    LoadMacro(macroName)
    {

        if (!macroName)
            return
        debug ? debug("Loading " . macroName . " in macro manager")
        this.ClearCurrentMacro()
        value := xml.Get("macro", macroName, "value")

        StringReplace, value, value, ``n, `n, all
        Loop, Parse, value, `n
            this.currentMacro.Items.Add("", A_LoopField) ; add contents of macro to listview.

        this.btnStartRecord.Enable()

    }

    Load(name = "", new = 0)
    {
        Loop % this.macroList.Items.Count
            this.macroList.Items.Delete(1)
        debug ? debug("Loading macro manager")
        macros := xml.List("macros", "|")
        Loop, Parse, macros, |
            if (Trim(A_LoopField, "`n`r "))
                this.macroList.Items.Add("", A_LoopField) ; Add each macro to the listview.
        this.Show()

        if (name)
        {
            ControlGet, macros, List, , % this.macroList.ClassNN, A ; Get all the keys from the listbox
            StringSplit, macroName, macros, `n
            Loop % macroName0
                if (name = macroName%A_Index%)
                    index := A_Index

            ControlFocus, % this.macroList.ClassNN, A
            this.macroList.Items.Modify(index, "Focus")
            this.macroList.Items.Modify(index, "Select")
        }
        if (new)
            this.btnAdd_Click(1)
    }

    UpdateMacro()
    {
        if (!this.macroList.FocusedIndex)
            return
        ControlGet, pressedKeys, List, , SysListView322, A ; Get all the keys from the listbox
        StringReplace, pressedKeys, pressedKeys, `n, ``n, All ; Changes newlines to `n so it can be stored in xml
        selectedRow := this.macroList.FocusedIndex
        macroName := this.macroList.Items[selectedRow][1]
        debug ? debug("Updated macro: " . macroName)
        xml.AddMacro(macroName, pressedKeys) ; Add the macro to xml.
    }

    ;Called when the window was destroyed (e.g. closed here)
	PreClose()
	{
        this.btnStopRecord_Click()
        this.ClearCurrentMacro()

        xml := new Xml(currentXml)
        this.oldMacroName := "", this.selectedRow := 0
        this.gui.Enabled := true
	}
}

EditName:
    Send, {F2}
return

DeleteName:
    gui.Macro.btnDelete_Click()
return

Edit:
    Send, {F2}
return

Delete:
    selectedRow := gui.Macro.currentMacro.FocusedIndex
    gui.Macro.currentMacro.Items.Delete(selectedRow)
return

InsertDelay:
    selectedRow := gui.Macro.currentMacro.FocusedIndex + 1
    if (!selectedRow)
        selectedRow := 1
    gui.Macro.currentMacro.Items.Insert(selectedRow, "", "Sleep, 100")
return

MouseEvent:
    selectedRow := gui.Macro.currentMacro.FocusedIndex + 1

    if (A_ThisMenu = "Wheel")
    {
        if (A_ThisMenuItem = "Forward")
            event := "{" . A_ThisMenu . "Up}"
        else if (A_ThisMenuItem = "backwards")
            event := "{" . A_ThisMenu . "Down}"
    }
    else if (A_ThisMenuItem = "click")
    {
        event := "{" . A_ThisMenu . " Down}"
        gui.Macro.currentMacro.Items.Insert(selectedRow, "", event)

        event := "{" . A_ThisMenu . " Up}"
        gui.Macro.currentMacro.Items.Insert(selectedRow + 1, "", event)
        return
    }
    else
        event := "{" . A_ThisMenu . " " . A_ThisMenuItem . "}"

    gui.Macro.currentMacro.Items.Insert(selectedRow, "", event)
    gui.UpdateMacro()
return


record:
    if (!initial)
    {
        initial := 1

        ; load the script to monitor key strokes.
        AhkRecorder.ahkDll(A_ScriptDir . "\res\ahk\recorder.ahk")
        AhkRecorder.ahkAssign("delay", (globalDelay ? "1" : "0"))
        AhkRecorder.ahkAssign("mouseClicks", (globalClick ? "1" : "0"))
        While (!AhkRecorder.ahkReady()) ;wait for the script to be ready
            Sleep 10
    }

    msg := AhkRecorder.ahkGetVar("msg")

    if (msg != oldMsg)
    {
        if (msg)
        {
            StringSplit, msg, msg, `n
            Loop % msg0-1
                gui.Macro.currentMacro.Items.Add("", msg%A_Index%) ; Add the key to listview.
        }
        Rows := gui.Macro.currentMacro.Items.Count
        gui.Macro.currentMacro.Items.Modify(rows, "vis") ; Makes sure the added key is visible.
    }
    if (gui.Macro.StopRecording)
    {
        AhkRecorder.ahkTerminate()
        initial := 0
        SetTimer, record, off
        Return
    }
    oldMsg := msg
return
