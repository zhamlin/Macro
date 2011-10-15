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
            this.delayCheckbox := this.Tabs[2].AddControl("CheckBox", "delayCheckbox", "x44 y42 w104 h17", "Profile Switching")
        }
    }

    __New(mainGui, owner)
    {
        this.Title := "Settings"
        this.gui   := mainGui
        this.Owner := owner, this.OwnerAutoClose := 1, this.MinimizeBox := 0
        this.Load()
    }

    Load(show = 0) {
        checked := Ini.Settings.ProfileSwitching ? Ini.Settings.ProfileSwitching : 0
        delay   := Ini.Settings.ProfileDelay
        startup := Ini.Settings.runOnStartUp ? Ini.Settings.runOnStartUp : 0

        this.tabControl1.Tabs[2].Controls.delaySlider.Value     := delay
        this.tabControl1.Tabs[2].Controls.settingsDelay.text    := delay
        this.tabControl1.Tabs[2].Controls.delayCheckbox.Checked := checked
        this.tabControl1.Tabs[1].Controls.startUp.Checked       := startup
        if (show)
        {
            this.ChangeControls(Ini.Settings.ProfileSwitching)
            this.Show()
        }
    }

    SettingsOK_Click() {
        Ini.Save(A_ScriptDir . "\res\settings.ini")
        RunOnStartUp(Ini.Settings.runOnStartUp, "Macro System")

        this.Hide()
    }

    SettingsCancel_Click() {
        Ini := new Ini(A_ScriptDir . "\res\settings.ini")
        this.Hide()
    }

    settingsDelay_TextChanged() {
        ControlGetText, value, Edit1, A
        if (!value)
            value := 1
        this.tabControl1.Tabs[2].Controls.delaySlider.Value := value
    }

    tabControl1_Click(TabIndex)
    {
        if (tabIndex.Text = "Profile")
            this.ChangeControls(Ini.Settings.ProfileSwitching)
    }

    startUp_CheckedChanged() {
        checked := this.tabControl1.Tabs[1].Controls.startUp.Checked
        Ini.Settings.runOnStartUp := checked
    }

    delayCheckbox_CheckedChanged() {
        checked := this.tabControl1.Tabs[2].Controls.delayCheckbox.Checked
        this.ChangeControls(checked)
        Ini.Settings.ProfileSwitching := checked
    }

    ChangeControls(Enabled = 0) {
        this.tabControl1.Tabs[2].Controls.delaySlider.Enabled   := Enabled
        this.tabControl1.Tabs[2].Controls.settingsDelay.Enabled := Enabled
        this.tabControl1.Tabs[2].Controls.settingsText.Enabled  := Enabled
    }

    delaySlider_SliderMoved() {
        value := this.tabControl1.Tabs[2].Controls.delaySlider.Value
        this.tabControl1.Tabs[2].Controls.settingsDelay.text := value
        Ini.Settings.ProfileDelay := value
    }
}
