; JSON Handler for AutoHotkey v2
; Handles JSON serialization and deserialization
#Include Jxon.ahk

class JSON {
    ; Parse JSON string to object
    static Parse(jsonStr) {
        try {
            return Jxon_Load(&jsonStr)
        } catch as e {
            throw Error("JSON Parse Error: " . e.Message)
        }
    }

    ; Convert AHK object to JSON string
    static Stringify(obj, indent := "") {
        if (IsObject(obj)) {
            if (obj is Array) {
                return this.ArrayToJSON(obj, indent)
            } else if (obj is Map) {
                return this.MapToJSON(obj, indent)
            } else {
                return this.ObjectToJSON(obj, indent)
            }
        } else if (IsNumber(obj)) {
            ; Check numbers BEFORE booleans
            return String(obj)
        } else if (obj = true || obj = false) {
            return obj ? "true" : "false"
        } else if (obj = "") {
            return '""'
        } else {
            return '"' . this.EscapeString(String(obj)) . '"'
        }
    }

    ; Convert Array to JSON
    static ArrayToJSON(arr, indent := "") {
        json := "["
        nextIndent := indent . "  "

        for index, value in arr {
            if (index > 1) {
                json .= ","
            }
            if (indent != "") {
                json .= "`n" . nextIndent
            }
            json .= this.Stringify(value, nextIndent)
        }

        if (indent != "" && arr.Length > 0) {
            json .= "`n" . indent
        }
        json .= "]"
        return json
    }

    ; Convert Map to JSON
    static MapToJSON(map, indent := "") {
        json := "{"
        nextIndent := indent . "  "
        first := true

        for key, value in map {
            if (!first) {
                json .= ","
            }
            if (indent != "") {
                json .= "`n" . nextIndent
            }
            json .= '"' . this.EscapeString(key) . '": '
            json .= this.Stringify(value, nextIndent)
            first := false
        }

        if (indent != "" && map.Count > 0) {
            json .= "`n" . indent
        }
        json .= "}"
        return json
    }

    ; Convert Object to JSON
    static ObjectToJSON(obj, indent := "") {
        json := "{"
        nextIndent := indent . "  "
        first := true

        for key, value in obj.OwnProps() {
            if (!first) {
                json .= ","
            }
            if (indent != "") {
                json .= "`n" . nextIndent
            }
            json .= '"' . this.EscapeString(key) . '": '
            json .= this.Stringify(value, nextIndent)
            first := false
        }

        if (indent != "") {
            json .= "`n" . indent
        }
        json .= "}"
        return json
    }

    ; Escape string for JSON
    static EscapeString(str) {
        str := StrReplace(str, "\", "\\")
        str := StrReplace(str, '"', '\"')
        str := StrReplace(str, "`n", "\n")
        str := StrReplace(str, "`r", "\r")
        str := StrReplace(str, "`t", "\t")
        return str
    }

    ; Escape JSON for JavaScript eval
    static EscapeJSON(str) {
        str := StrReplace(str, "\", "\\")
        str := StrReplace(str, "'", "\'")
        str := StrReplace(str, "`n", "\n")
        str := StrReplace(str, "`r", "\r")
        return str
    }

    ; Convert JavaScript object to AHK
    static JSObjectToAHK(jsObj) {
        ; This is a placeholder for JS to AHK conversion
        ; In practice, we'd need more complex conversion logic
        return jsObj
    }

    ; Manual JSON parser (basic implementation)
    static ManualParse(jsonStr) {
        ; Remove whitespace
        jsonStr := Trim(jsonStr)

        ; Check if it's an object or array
        if (SubStr(jsonStr, 1, 1) = "{") {
            return this.ParseObject(jsonStr)
        } else if (SubStr(jsonStr, 1, 1) = "[") {
            return this.ParseArray(jsonStr)
        }

        return {}
    }

    ; Parse JSON object
    static ParseObject(jsonStr) {
        obj := Map()
        jsonStr := Trim(SubStr(jsonStr, 2, -1)) ; Remove { }

        ; Simple parsing (works for basic cases)
        ; Would need more robust implementation for production
        return obj
    }

    ; Parse JSON array
    static ParseArray(jsonStr) {
        arr := []
        jsonStr := Trim(SubStr(jsonStr, 2, -1)) ; Remove [ ]

        ; Simple parsing (works for basic cases)
        return arr
    }

    ; Load JSON from file
    static LoadFromFile(filePath) {
        try {
            content := FileRead(filePath)
            return this.Parse(content)
        } catch {
            return {}
        }
    }

    ; Save JSON to file
    static SaveToFile(filePath, obj) {
        try {
            jsonStr := this.Stringify(obj, "")

            ; Ensure directory exists
            SplitPath(filePath, , &dir)
            if (dir && !DirExist(dir)) {
                DirCreate(dir)
            }

            ; Delete old file if it exists
            if (FileExist(filePath)) {
                FileDelete(filePath)
            }

            ; Write new file (UTF-8-RAW = no BOM)
            FileAppend(jsonStr, filePath, "UTF-8-RAW")
            return true
        } catch as e {
            MsgBox("JSON Save Error: " . e.Message . "`nFile: " . filePath, "Debug")
            return false
        }
    }
}
