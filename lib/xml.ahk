Class Xml
{

    __New(xmlpath = "") {
        if (RegExMatch(xmlpath, "\.xml$"))
            FileRead, xmldata, % xmlpath
        if (!xmldata)
        {
            ;default xml contents
            xmldata =
            ( LTrim
                <?xml version="1.0"?>
                <profile>
                    <info>
                        <name>Default</name>
                        <exe></exe>
                    </info>
                    <keys>
                    </keys>
                    <macros>
                    </macros>
                    <textblocks>
                    </textblocks>
                    <scripts>
                    </scripts>
                 </profile>
            )
        }
        try {
             this.oXML := ComObjCreate("MSXML2.DOMDocument")
        }
        this.oXML.async := False
        if (this.doc := this.oXML.loadXML(xmldata))
            this.doc.Save(xmlpath)
        else
            return 0
        this.root := this.oXml.documentElement
    }

    ; Add an attribute to node.
    AddAttribute(ParentNode, node, attribute, value) {
        node := this.root.selectSingleNode("//profile/" . ParentNode . "/" . node).attributes
        newAtt := this.oXml.createAttribute(attribute)
        newAtt.value := value
        node.setNamedItem(newAtt)
    }

    Delete(NodeName, child) {
        if (NodeName = "keys") ; if deleting a key, turn the hotkey off.
        {
            try {
                key := this.GetAttribute(child) ; Gets hotkey
                Hotkey, % "$" . key, off
            }
        }
        node := this.oXml.selectNodes("//" . NodeName . "/" . child . "")
        Loop % node.length
            node.removeNext()
    }

    AddNode(ParentNode, ChildNode, NumItem=0) {
        oNode := this.oXML.createElement(ChildNode)
        this.oXML.getElementsByTagName(ParentNode).Item(NumItem).appendChild(oNode)
    }

    InsertText(NodeName, text, NumItem=0) {
        x := this.oXML.getElementsByTagName(NodeName).Item(NumItem)
        x.appendChild(this.oXML.createTextNode(text))
    }

    Insert(NodeName, child, key, value) {
        node := this.oXml.selectSingleNode("//" . NodeName . "/" . child . "/" . key)
        node.appendChild(this.oXml.createTextNode(value))
    }

    ; Adds a key to xml file.
    AddKey(key, type, value, options = "None", repeat = "None") {
        if (this.Exist("key", key))
            this.Delete("keys", key)
        this.AddNode("keys", key)
        this.AddAttribute("keys", key, "options", options)

        this.AddNode(key, "type")
        this.AddNode(key, "value")
        this.AddNode(key, "repeat")

        this.Insert("keys", key, "type", type)
        this.Insert("keys", key, "value", value)
        this.Insert("keys", key, "repeat", repeat)

    }

    AddMacro(name, value) {
        if (this.Exist("macro", name))
            this.Delete("macros", name)

        this.AddNode("macros", name)
        this.AddNode(name, "value")

        this.Insert("macros", name, "value", value)
    }

    AddText(name, value, delay) {
        if (this.Exist("textblock", name))
            this.Delete("textblocks", name)

        this.AddNode("textblocks", name)
        this.AddNode(name, "value")
        this.AddNode(name, "delay")

        this.Insert("textblocks", name, "value", value)
        this.Insert("textblocks", name, "delay", delay)
    }

    ; Check to see if the key is already in xml file.
    Exist(type, name) {
        node := this.root.selectSingleNode("//" . type . "s").childNodes
        Loop % node.length
            if (name = node.item[a_index-1].tagName)
                return 1
    }

    Rename(type, oldName, newName) {
        if (!this.Exist(type, oldName))
            return
        else if (type = "macro")
        {
            value := this.Get("macro", oldName, "value")
            this.Delete("macros", oldName)
            this.AddMacro(newName, value)
        }
    }

    Get(type, name = "", what = "") {
        if (type = "key")
            return ( this.oXml.selectSingleNode("/profile/keys/" . name . "/" . what).text )
        else if (type = "macro")
            return ( this.oXml.selectSingleNode("/profile/macros/" . name . "/" . what).text )
        else if (type = "name")
            return ( this.oXml.selectSingleNode("/profile/info/name").text )
        else if (type = "exe")
            return ( this.oXml.selectSingleNode("/profile/info/exe").text )
        else if (type = "textblock")
            return ( this.oXml.selectSingleNode("/profile/textblocks/" . name . "/" . what).text )
    }

    GetAttribute(name) {
        if (!name)
            return
        node := this.oXml.selectSingleNode("/profile/keys/" . name)
        attrib := node.attributes
        return attrib.getQualifiedItem("options", "").value
    }

    GetScript() {
        this.oXML.preserveWhiteSpace := true
        node := this.oXml.selectSingleNode("/profile/info")
        attrib := node.attributes
        attrib := attrib.getQualifiedItem("script", "").value
        this.oXML.preserveWhiteSpace := false
        return attrib
    }

    Set(type, value) { ; Change the profiles name or exe
        node := this.oXml.selectNodes("//info/" . type) ; select the node to delete
        node.removeNext() ; delete node
        this.AddNode("info", type)
        node := this.oXml.selectSingleNode("//info/" . type)
        node.appendChild(this.oXml.createTextNode(value)) ; add new value to node
    }

    List(type, delimiter = "") { ; Get all of the child nodes for that type
        node := this.root.selectSingleNode("//" . type).childNodes
        if (!node.length)
            return
        Loop % node.length
            keys .= node.item[a_index-1].tagName . delimiter
        return keys
    }


    Save(dir, name) {
        FileDelete % dir . "/" . name . ".xml"
        FileAppend, % TidyUp(this.oXml.xml), % dir . "/" . name . ".xml"
    }

}

indent(amount) {
    Loop % amount
        t .= A_Tab
    return t
}

TidyUp(xmlInfo) {
    StringReplace, xmlInfo, xmlInfo, `r, , All
    StringReplace, xmlInfo, xmlInfo, `n, , All
    StringReplace, xmlInfo, xmlInfo, <?xml version="1.0"?>
    RegExMatch(xmlInfo, "\s??\<.*?\>", root), root := Trim(root, "`n ")
    StringReplace, xmlInfo, xmlInfo, % root
    StringReplace, xmlInfo, xmlInfo, %A_Tab%, , All
    xmlInfo := Trim(xmlInfo, " "), newxml := "<?xml version=""1.0""?>`n" . root . "`n", indent := 1
    Loop, Parse, xmlInfo, <
    {
        if (!Trim(A_LoopField))
            Continue
        else if (cont)
            newXml .= "<" . A_LoopField . "`n", cont := 0

        else if (!InStr(A_LoopField, "/"))
        {
            if (SubStr(A_LoopField, 0) != ">")
                cont := 1, newXml .= indent(indent) . "<" . A_LoopField
            else
                newXml .= indent(indent) . "<" . A_LoopField . "`n", indent++
        }
        else
            indent--, newXml .= indent(indent) . "<" . A_LoopField . "`n"
    }
    return newXml
}
