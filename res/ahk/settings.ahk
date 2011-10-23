Class settings Extends CGUI
{

    SettingsOK := this.AddControl("Button", "SettingsOK", "x300 y341 w80 h26", "OK")
    SettingsCancel := this.AddControl("Button", "SettingsCancel", "x386 y341 w80 h26", "Cancel")

    Class tabControl1
    {
        static Type := "Tab"
        static Options := "x12 y8 w454 h331"
        static Text := "General|Profile"
        __New(GUI)
        {
            this.Tabs[1].AddControl("GroupBox", "groupBox1", "x28 y42 w434 h82", "Startup")
            this.startUp := this.Tabs[1].AddControl("CheckBox", "startUp", "x71 y61 w93 h17", "Run at startup")
            this.update := this.Tabs[1].AddControl("CheckBox", "update", "x71 y91 w150 h25", "Check for updates on start")
            this.show := this.Tabs[1].AddControl("CheckBox", "show", "x221 y91 w140 h25", "Show Gui on start")

            this.profileSwitching := this.Tabs[2].AddControl("CheckBox", "profileSwitching", "x44 y42 w104 h17", "Profile Switching")
        }
    }

    __New(mainGui, owner)
    {
        this.Title := "Settings"
        this.gui   := mainGui
        this.Owner := owner, this.OwnerAutoClose := 1, this.MinimizeBox := 0
        this.Load()
    }

    Load(showGui = 0) {
        checked := Ini.Settings.ProfileSwitching ? Ini.Settings.ProfileSwitching : 0
        startup := Ini.Settings.runOnStartUp ? Ini.Settings.runOnStartUp : 0
        update  := Ini.Settings.UpdateOnStart ? Ini.Settings.UpdateOnStart : 0
        show    := Ini.Settings.ShowOnStart ? Ini.Settings.ShowOnStart : 0


        this.tabControl1.Tabs[1].Controls.startUp.Checked       := startup
        this.tabControl1.Tabs[1].Controls.update.Checked        := update
        this.tabControl1.Tabs[1].Controls.show.Checked          := show
        this.tabControl1.Tabs[1].Controls.show.Checked          := checked

        if (showGui)
            this.Show()

    }

    SettingsOK_Click() {
        Ini.Save(A_ScriptDir . "\res\settings.ini")
        RunOnStartUp(Ini.Settings.runOnStartUp, "Macro System")

        this.gui.Enabled := true
        this.Hide()
    }

    SettingsCancel_Click() {
        Ini := new Ini(A_ScriptDir . "\res\settings.ini")
        this.gui.Enabled := true
        this.Hide()
    }

    startUp_CheckedChanged() {
        checked := this.tabControl1.Tabs[1].Controls.startUp.Checked
        Ini.Settings.runOnStartUp := checked
    }

    update_CheckedChanged() {
        checked := this.tabControl1.Tabs[1].Controls.update.Checked
        Ini.Settings.UpdateOnStart := checked
    }

    profileSwitching_CheckedChanged() {
        checked := this.tabControl1.Tabs[2].Controls.profileSwitching.Checked
        Ini.Settings.ProfileSwitching := checked
    }

    show_CheckedChanged() {
        checked := this.tabControl1.Tabs[1].Controls.show.Checked
        Ini.Settings.ShowOnStart := checked
    }

    PreClose() {
        this.gui.Enabled := true
    }
}
