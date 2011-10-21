Class Textblock Extends CGUI
{

	__New(mainGui, owner = "")
	{
        this.AddControl("Text", "a", "x6 y11 w417 h13", "Name:")
        this.edtName := this.AddControl("Edit", "edtName", "x6 y31 w417 h23" ,"")
        this.AddControl("Text", "d", "x6 y67 w417 h16 ", "Enter your text:")
        this.edtText := this.AddControl("Edit", "edtText", "x6 y86 w417 h242" ,"")
        this.AddControl("GroupBox", "z", "x6 y343 w417 h65","")
        this.chkDelay := this.AddControl("Checkbox", "chkDelay", "x18 y343 w181 h13 ", "Use delays between characters")
        this.edtDelay := this.AddControl("Edit", "edtDelay", "x40 y372 w65 h23 ", "0")
        this.txtDelay := this.AddControl("Text", "txtDelay", "x112 y377 w77 h13 ", "milliseconds")
        this.AddControl("Button", "btnClear", "x6 y465 w75 h23 ", "Clear")
        this.btnOK := this.AddControl("Button", "btnOK", "x87 y465 w75 h23 ", "OK")
        this.AddControl("Button", "btnCancel", "x168 y465 w75 h23 ", "Cancel")
        this.AddControl("Button", "l", "x348 y465 w75 h23 ", "Help")

        this.edtDelay.Disable()
        this.txtDelay.Disable()
        this.btnOK.Disable()

        this.gui := mainGui
        if (owner)
            this.Owner := owner, this.OwnerAutoClose := 1, this.MinimizeBox := 0

        this.Toolwindow := 1
		this.Title := "Text Block Manager"
	}

    edtName_TextChanged()
    {
        ; Checking if the edit has text in it.
        if (this.edtName.text)
            this.btnOK.Enable()
        else
            this.btnOK.Disable()
    }
    chkDelay_CheckedChanged()
    {
        if (this.chkDelay.Checked)
        {
            this.edtDelay.Enable()
            this.txtDelay.Enable()
        }
        else
        {
            this.edtDelay.Disable()
            this.txtDelay.Disable()
        }
    }

    btnClear_Click()
    {
        this.edtText.text := ""
    }

    btnCancel_Click()
    {
        debug ? debug("Hiding textblock gui")
        this.Hide()
    }

    btnOK_Click()
    {
        name := this.edtName.text
        text := this.edtText.text

        ; Checking to see if the delay is checked and has a value.
        if (this.edtDelay.Text && this.chkDelay.Checked)
            delay := this.edtDelay.Text
        else
            delay := -1
        firstChar := SubStr(name, 1, 1)

        if (InStr(name, A_Space))
        {
            MsgBox, 48, , No spaces allowed in name.
            return
        }
        else if firstChar is not Alpha
        {
            MsgBox, 48, , Macro names must start with a letter.
            return
        }
        else if (!name)
            return

        StringReplace, text, text, `n, ``n, All ; Change newlines to `n for storage in xml
        xml.AddText(name, text, delay)
        xml.Save(A_ScriptDir . "\res\Profiles\" . xml.Get("name") . ".xml") ; Save xml file.

        this.name := name
        this.edtName.text := "", this.edtText.text := "", this.editDelay := -1
        this.Hide()

        selectedRow := this.gui.keys.FocusedIndex
        key := this.gui.keys.Items[selectedRow][1]
        options := xml.GetAttribute(key)
        type := this.gui.keys.Items[selectedRow][2]
        repeat := this.gui.keys.Items[selectedRow][5]

        debug ? debug("Created textblock: " . name . " for key: " . key)

        xml.AddKey(key, "Textblock", this.name, options, repeat)
        StringReplace, options, options, % key
        this.gui.keys.Items.Modify(selectedRow, "", key, "Textblock", this.name, options, repeat)
        xml.Save(A_ScriptDir . "\res\Profiles\" . xml.Get("name") . ".xml") ; Save xml file.
        Hotkeys()
    }

    Load(textblockName)
    {
        this.Done := 0
        if (!xml.Exist("textblock", textblockName))
        {
            debug ? debug("Showing textblock gui")
            this.Show()
            return
        }

        text := xml.Get("textblock", textblockName, "value")
        Transform, text, Deref, % text ; turn ``n into actual new lines
        this.edtText.text := text
        this.edtName.Text := textblockName
        delay := xml.Get("textblock", textblockName, "delay")

        if (delay > 0)
        {
            ; Enable Delay edit box
            this.edtDelay.Enable()
            this.txtDelay.Enable()
            this.chkDelay.Checked := true
            this.edtDelay.Text := delay
        }
        debug ? debug("Loaded textblock: " . textblockName)
        this.Show()
    }

}
