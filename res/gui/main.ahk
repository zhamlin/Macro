Class Main Extends CGUI
{

    __New()
    {
        this.AddControl("Text", "txtVersion", "x785 y420 w22 h20 ", "v" . version)
        this.tabControl := this.AddControl("Tab", "tabControl", "x12 y10 w800 h410 hwndTabControl1", "Keys|Script")

        this.AddControl("Text", "txtProfile", "x302 y12 w150 h15 ", "Current Profile:")
        this.drpProfiles := this.AddControl("DropDownList", "drpProfiles", "x380 y8 w430 h400 vDropDownList", "")
        this.tabControl.tabs[1].AddControl("Button", "btnAdd", "x330 y372 w75 h23 ", "&Add")
        this.keys := this.tabControl.tabs[1].AddControl("ListView", "keys", "x22 y38 w780 h317 Grid", "Key       |Type           |Name          |Options|Repeat")

        this.tabControl.tabs[2].AddControl("Button", "btnSave", "x400 y390 w75 h23 ", "&Save")

        this.MenuBar := New CMenu("Main")
        ProfileMenu := New CMenu("ProfileMenu")
        ProfileMenu.AddMenuItem("New", "ProfileOpen")
        ProfileMenu.AddMenuItem("Delete", "DeleteProfile")
        ProfileMenu.AddMenuItem("", "")
        ProfileMenu.AddMenuItem("Exit", "Exit")
        this.ProfileMenu := ProfileMenu

        Edit := New CMenu("Edit")
        Edit.AddMenuItem("Profile Properties", "EditProfile")
        Edit.AddMenuItem("Settings", "EditSettings")
        Edit.AddMenuItem("", "")
        Edit.AddMenuItem("Macro Manager", "EditMacro")
        this.Edit := Edit

        this.MenuBar.AddSubMenu("Profile", ProfileMenu)
        this.MenuBar.AddSubMenu("Edit", Edit)

        Menu, MacrosMenu, Add, DeleteMe, Exit ; Place holder
        Menu, ContextMenu, Add, Assign Macros, :MacrosMenu
        Menu, ContextMenu, Add, Assign Textblock, AssignTextblock
        Menu, ContextMenu, Add, Assign Script, AssignScript

        Menu, Options, Add, Toggle, Options
        Menu, Options, Add, Pressed, Options
        Menu, Options, Add, None, Options
        Menu, ContextMenu, Add, Repeat, :Options
        ; Menu, ContextMenu, Add, Assign Single key, Exit
        ; Menu, ContextMenu, Add, Assign Script, Exit
        Menu, ContextMenu, Add
        Menu, ContextMenu, Add, Show Macro Manager, ShowMacroManager
        Menu, ContextMenu, Add
        Menu, ContextMenu, Add, Disable, DisableKey
        Menu, ContextMenu, Add, Delete, DeleteKey

        Menu, MacrosMenu, Delete, DeleteMe

        Menu, Tray, NoStandard

        Menu, Tray, Add, Show, Show
        Menu, Tray, Add
        Menu, Tray, Add, Suspend Hotkeys, TurnOff
        Menu, Tray, Add, Exit, Exit

        this.LoadProfiles()

        this.AddMenuBar(this.MenuBar)
        this.Title := "Main Gui"
        this.Show("h440 w820")

        ControlGet, Tabhwnd, Hwnd,, % this.tabControl.ClassNN
        ; Add scintilla control to tab.
        this.hSci := SCI_Add(this.hwnd, 22, 38, 780, 340, "Child Border Visible GROUP TABSTOP ", "", A_ScriptDir . "\res\dll\scilexer.dll")
        Control, Hide,,, % "ahk_id" this.hSci

        Control, ChooseString, Default, % this.drpProfiles.ClassNN, A
        this.hwnd := WinActive("A")

        this.Macro := new MacroRecorder(this, this.hwnd)
        this.Profile := new Profile(this, this.hwnd)
        this.Textblock := new Textblock(this, this.hwnd)
        this.Settings := new Settings(this, this.hwnd)

        SCI_SetLexer("SCLEX_AU3")
        SCI_StyleClearAll()
        SCI_SetMarginWidthN(0, 25) ; Add line numbers to margin of Sctinilla control.
        SCI_SetWrapMode(true) ; Allow line wrapping

        Loop 3 ; Add keywords to Scintilla control.
            keywords .= keywords(A_Index) . A_Space
        SCI_SetKeywords(0, keywords)

        SCI_StyleSetFore(5, "blue") ; key words
        SCI_StyleSetFore(1, "green") ; Comments
        SCI_StyleSetFore(7, "0x108080") ; Quotes
        SCI_StyleSetFore(10, "0x108080") ; Quotes

        SCI_StyleSetFore(3, "red") ; numbers
        SCI_StyleSetFore(8, "red") ; Symbols

        debug ? debug("Loaded")
    }

    Exit()
    {
        debug ? debug("Exiting")
        ExitApp
    }

    DeleteProfile()
    {
        SelectedIndex := this.drpProfiles.SelectedIndex
        ControlGet, var, List, Focused, % this.drpProfiles.ClassNN, A ; Get text from dropdown
        StringSplit, var, var, `n
        selectedText := var%SelectedIndex%

        MsgBox, 52, , Are you sure you want to delete:`n%selectedText%
        IfMsgBox, No
            return

        SplitPath, currentXml,,,, name
        FileDelete % currentXml
        FileDelete A_ScriptDir . "\res\scripts\" . name . ".ahk"

        this.LoadProfiles()
        Control, Choose, 1, % this.drpProfiles.ClassNN, A ; Select profile
        debug ? debug("Deleted profile: " . currentXml)
    }

    ProfileOpen()
    {
        this.Profile.Show()
    }

    EditSettings()
    {
        this.Settings.Show()
    }

    EditProfile()
    {
        this.Profile.Load(currentXml)
    }

    EditMacro()
    {
        this.Macro.Load()
    }

    btnSave_Click()
    {
        global ahkDll
        SplitPath, currentXml,,,, Name
        FileRead, oldScript, % A_ScriptDir . "\res\scripts\" . name . ".ahk"
        SCI_GetText(SCI_GetLength() + 1, script)

        if (script != oldScript || !script)
        {
            AhkScript.ahkTerminate()
            AhkScript := AhkDllThread(ahkDll)
            AhkScript.ahkTextDll("")

            While (!AhkScript.ahkReady())
                Sleep, 10

            if (!script)
                SCI_SetText(script := ";Key = key pressed`n;Event = Can be Pressed, Down, or Released`n;time = time since key was pressed.`n`nOnEvent(key, event, time = 0, currentProfile = """") {`n`n}")

            AhkScript.addScript(script)
            xml.AddScript(script)

            FileDelete % A_ScriptDir . "\res\scripts\" . name . ".ahk"
            FileAppend, % script, % A_ScriptDir . "\res\scripts\" . name . ".ahk"
        }
    }

    tabControl_Click(TabIndex)
    {
        Control, % (TabIndex.text = "Script") ? "Show" : "Hide" ,,, % "ahk_id" this.hSci
    }

    keys_ContextMenu()
    {
        if (!this.keys.FocusedIndex)
            return

        debug ? debug("Showing contex menu")

        selectedRow := this.keys.FocusedIndex
        repeat := this.keys.Items[selectedRow][5]
        type := this.keys.Items[selectedRow][2]

        if (type = "script" || "disabled")
        {
            Menu, Options, Disable, Toggle
            Menu, Options, Disable, Pressed
            Menu, Options, Disable, None
        }
        else
        {
            Menu, Options, Enable, Toggle
            Menu, Options, Enable, Pressed
            Menu, Options, Enable, None
        }

        ; Uncheck all options
        Menu, Options, UnCheck, Toggle
        Menu, Options, UnCheck, Pressed
        Menu, Options, UnCheck, None

        ; Check selected option
        Menu, Options, Check, % repeat

        if (this.keys.Items[selectedRow][2] = "macro")
            Menu, MacrosMenu, Enable, Edit Macro
        else
            Menu, MacrosMenu, Disable, Edit Macro

        Menu, ContextMenu, Show
    }

    drpProfiles_SelectionChanged(SelectedIndex)
    {
        if (!this.drpProfiles.SelectedIndex)
            return

        SelectedIndex := this.drpProfiles.SelectedIndex
        ControlGet, var, List, Focused, % this.drpProfiles.ClassNN, % "ahk_id " this.hwnd ; Get text from dropdown
        StringSplit, var, var, `n

        if (!selectedText := var%SelectedIndex%)
            return
        else if (selectedText = "Default")
        {
            this.edit[1].Enabled := false
            this.ProfileMenu[2].Enabled := false
        }
        else
        {
            this.edit[1].Enabled := true
            this.ProfileMenu[2].Enabled := true
        }
        debug ? debug("Changed profile to: " . selectedText)
        this.LoadProfile(A_ScriptDir . "\Profiles\" . selectedText . ".xml")
    }

    btnAdd_Click()
    {
        keys := xml.List("keys", ",")
        options := HotkeyGUI(0, "", 2046, true) ; 2046
        if (!options)
            return
        else if options in %keys%
            return

        key := Trim(RegExReplace(options, "([\*\<\>\~]|(?<!_)Up)"))
        StringReplace, optionsWithoutKey, options, % key, % A_Space
        debug ? debug("Addied key: " . key)

        this.keys.Items.Add("", key, "", "", optionsWithoutKey, "None")
        xml.AddKey(key, "", "", options)
        xml.Save(A_ScriptDir . "\Profiles\", xml.Get("name")) ; Save xml file.
    }

    LoadProfiles()
    {
        debug ? debug("Clearing profiles from DropDownList")
        Loop % this.drpProfiles.Items.Count ; Clear all items from dropdown
            Control, Delete, 1, % this.drpProfiles.ClassNN, A

        profiles := GetProfiles()
        StringReplace, profiles, profiles, .xml,, All
        debug ? debug("Adding profiles from DropDownList")
        this.drpProfiles.Items.Add(profiles)
    }

    ClearKeys()
    {
        Loop % this.keys.Items.Count
            this.keys.Items.Delete(1)
    }

    LoadProfile(profile)
    {
        try
        {
            Hotkeys(1)
        }

        currentXml := profile
        xml := new Xml(currentXml)

        this.UpdateMacros()
        this.ClearKeys()

        keys := xml.List("keys", "|")
        Loop, Parse, keys, |
        {
            if (!A_LoopField)
                Continue
            type := xml.Get("key", A_LoopField, "type")
            value := xml.Get("key", A_LoopField, "value")
            repeat := xml.Get("key", A_LoopField, "repeat")
            options := xml.GetAttribute(A_LoopField)

            key := Trim(RegExReplace(options, "([\*\<\>\~]|(?<!_)Up)"))
            StringReplace, options, options, % key, % A_Space

            this.keys.Items.Add("", key, type, value, options, repeat)
        }
        SplitPath, profile,,,, name
        FileRead, script, % A_ScriptDir . "\res\scripts\" . name . ".ahk"

        if (!script)
            script := ";Key = key pressed`n;Event = Pressed, Down, or Released`n;time = time since key was pressed.`n`nOnEvent(key, event, time = 0, currentProfile = """") {`n`n}"

        AhkScript.ahkTerminate("")
        ScriptThread := AhkScript.ahktextdll("#Persistent`n#NoTrayIcon`nSetWorkingDir, " . A_ScriptDir . "\`n")
        AhkScript.addScript(script)

        SCI_SetText(script)

        Hotkeys()
    }

    UpdateKey(macroName)
    {
        debug ? debug("Updating keys macro")
        selectedRow := this.keys.FocusedIndex
        key := Trim(this.keys.Items[selectedRow][1])
        options := xml.GetAttribute(key)

        xml.AddKey(key, "Macro", macroName, options, "None")
        StringReplace, options, options, % key
        this.keys.Items.Modify(selectedRow, "", key, "Macro",  macroName, options)
        Hotkeys()
    }

    UpdateMacros()
    {
        Menu, MacrosMenu, DeleteAll
        Menu, MacrosMenu, Add, Create New Macro, CreateMacro
        Menu, MacrosMenu, Add, Edit Macro, EditMacro
        Menu, MacrosMenu, Add

        debug ? debug("Updating macros menu")

        macros := xml.List("macros", "|")
        Loop, Parse, macros, |
            if (Trim(A_LoopField, "`n`r "))
                Menu, MacrosMenu, Add, % A_LoopField, AssignMacro
    }


    ;Called when the window was destroyed (e.g. closed here)
    PreClose()
    {
        this.Macro.Hide()
        this.Profile.Hide()
        this.Macro.Hide()
        this.Hide()
        debug ? debug("Hiding all Guis")
    }

}

Exit:
    ExitApp
return

TurnOff:
    Suspend
return

Show:
    gui.Show()
return

ShowMacroManager:
CreateMacro:
    gui.Macro.Load("", (A_ThisLabel = "CreateMacro"))
return

EditMacro:
    Gosub, GetData
    gui.Macro.Load(name)
return

AssignMacro:
    Gosub, GetData
    xml.AddKey(key, "Macro", A_ThisMenuItem, options)
    StringReplace, options, options, % key
    gui.keys.Items.Modify(selectedRow, "", key, "Macro", A_ThisMenuItem, options)
    if (type = "textblock")
        xml.Delete("textblocks", name) ; Remove textblock
    xml.Save(A_ScriptDir . "\Profiles\", xml.Get("name")) ; Save xml file.
    debug ? debug("Assigned macro: " . A_ThisMenuItem . " to key: " . key)
    Hotkeys()
return

AssignTextblock:
    Gosub, GetData
    if (type = "textblock")
        gui.Textblock.Load(name), xml.Delete("textblocks", name)
    else
        gui.Textblock.Load("")
return

AssignScript:
    Gosub, GetData
    if (type = "textblock")
        xml.Delete("textblocks", name) ; Remove textblock
    xml.AddKey(key, "Script", "Script", options, "None")

    StringReplace, options, options, % key
    gui.keys.Items.Modify(selectedRow, "", key, "Script", "Script", options, "None")

    xml.Save(A_ScriptDir . "\Profiles\", xml.Get("name")) ; Save xml file.
    debug ? debug("Assigned Script to key: " . key)
    Hotkeys()
return

DeleteKey:
    Gosub, GetData
    gui.keys.Items.Delete(selectedRow) ; Clear row
    if (type = "textblock")
        xml.Delete("textblocks", name) ; Remove textblock

    xml.Delete("keys", key)
    xml.Save(A_ScriptDir . "\Profiles\", xml.Get("name")) ; Save xml file.
    debug ? debug("Deleted key: " . key)
return

DisableKey:
    Gosub, GetData
    if (type = "textblock")
        xml.Delete("textblocks", name) ; Remove textblock
    xml.AddKey(key, "Disabled", "Disabled", options)

    gui.keys.Items.Modify(selectedRow, "", key, "Disabled", "None")
    xml.Save(A_ScriptDir . "\Profiles\", xml.Get("name")) ; Save xml file.

    debug ? debug("Disabled key:" . key)
    Hotkeys()
return

Options:
    Gosub, GetData
    xml.AddKey(key, type, name, options, A_ThisMenuItem)
    StringReplace, options, options, % key

    gui.keys.Items.Modify(selectedRow, "", key, type, Name, options, A_ThisMenuItem)
    xml.Save(A_ScriptDir . "\Profiles\", xml.Get("name")) ; Save xml file.

    debug ? debug("Changed:" . key . "'s options")
    Hotkeys()
return

GetData:
    selectedRow := gui.keys.FocusedIndex
    key := Trim(gui.keys.Items[selectedRow][1])
    options := xml.GetAttribute(key)
    type := gui.keys.Items[selectedRow][2]
    name := gui.keys.Items[selectedRow][3]
    repeat := gui.keys.Items[selectedRow][5]
return

