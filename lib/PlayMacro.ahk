PlayMacro(macro, profile) {
    static oXML := ComObjCreate("MSXML2.DOMDocument")
    oXML.async := False  
    oXML.Load(profile)
    
    text := oXml.selectSingleNode("/profile/macros/" . macro . "/value").text
    StringReplace, text, text, ``n, `n, all
    
    Loop, Parse, text, `n
    {
        if (!A_LoopField)
            Continue
        if (InStr(A_LoopField, "Sleep,"))
        {
            Send % sendString
            sendString := ""
            Sleep % SubStr(A_LoopField, 8)
        }
        else
            sendString .= A_LoopField
    }
    Send % sendString
}