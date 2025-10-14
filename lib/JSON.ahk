/*
 *    "JSON_Beautify.ahk" by Joe DF (joedf@users.sourceforge.net)
 *    ______________________________________________________________________
 *    "Transform Objects & JSON strings into nice or ugly JSON strings."
 *    Uses VxE's JSON_FromObj()
 *    
 *    Released under The MIT License (MIT)
 *    ______________________________________________________________________
 *    
*/

JSON_Uglify(JSON) {
	if IsObject(JSON) {
		return JSON_FromObj(JSON)
	} else {
		if JSON is space
			return ""
		StringReplace,JSON,JSON, `n,,A
		StringReplace,JSON,JSON, `r,,A
		StringReplace,JSON,JSON, % A_Tab,,A
		StringReplace,JSON,JSON, % Chr(08),,A
		StringReplace,JSON,JSON, % Chr(12),,A
		StringReplace,JSON,JSON, \\, % Chr(1),A  ;watchout for escape sequence '\\', convert to '\1'
		_JSON:="", in_str:=0, l_char:=""
		Loop, Parse, JSON
		{
			if ( (!in_str) && (asc(A_LoopField)==0x20) )
				continue
			if( (asc(A_LoopField)==0x22) && (asc(l_char)!=0x5C) )
				in_str := !in_str
			_JSON .= (l_char:=A_LoopField)
		}
		StringReplace,_JSON,_JSON, % Chr(1),\\,A  ;convert '\1' back to '\\'
		return _JSON
	}
}

JSON_Beautify(JSON, gap:="`t") {
	;fork of http://pastebin.com/xB0fG9py
	JSON:=JSON_Uglify(JSON)
	StringReplace,JSON,JSON, \\, % Chr(1),A  ;watchout for escape sequence '\\', convert to '\1'
	
	indent:=""
	
	if gap is number
	{
		i :=0
		while (i < gap) {
			indent .= " "
			i+=1
		}
	} else {
		indent := gap
	}
	
	_JSON:="", in_str:=0, k:=0, l_char:=""
	
	Loop, Parse, JSON
	{
		if (!in_str) {
			if ( (A_LoopField=="{") || (A_LoopField=="[") ) {
				_s:=""
				Loop % ++k
					_s.=indent
				_JSON .= A_LoopField "`n" _s
				continue
			}
			else if ( (A_LoopField=="}") || (A_LoopField=="]") ) {
				_s:=""
				Loop % --k
					_s.=indent
				_JSON .= "`n" _s A_LoopField
				continue
			}
			else if ( (A_LoopField==",") ) {
				_s:=""
				Loop % k
					_s.=indent
				_JSON .= A_LoopField "`n" _s
				continue
			}
		}
		if( (asc(A_LoopField)==0x22) && (asc(l_char)!=0x5C) )
			in_str := !in_str
		_JSON .= (l_char:=A_LoopField)
	}
	StringReplace,_JSON,_JSON, % Chr(1),\\,A  ;convert '\1' back to '\\'
	return _JSON
}

; Copyright © 2013 VxE. All rights reserved.

; Serialize an object as JSON-like text OR format a string for inclusion therein.
; NOTE: scientific notation is treated as a string and hexadecimal as a number.
; NOTE: UTF-8 sequences are encoded as-is, NOT as their intended codepoint.
json_fromobj( obj ) {

	If IsObject( obj )
	{
		isarray := 0 ; an empty object could be an array... but it ain't, says I
		for key in obj
			if ( key != ++isarray )
			{
				isarray := 0
				Break
			}

		for key, val in obj
			str .= ( A_Index = 1 ? "" : "," ) ( isarray ? "" : json_fromObj( key ) ":" ) json_fromObj( val )

		return isarray ? "[" str "]" : "{" str "}"
	}
	else if obj IS NUMBER
		return obj
;	else if obj IN null,true,false ; AutoHotkey does not natively distinguish these
;		return obj

	; Encode control characters, starting with backslash.
	StringReplace, obj, obj, \, \\, A
	StringReplace, obj, obj, % Chr(08), \b, A
	StringReplace, obj, obj, % A_Tab, \t, A
	StringReplace, obj, obj, `n, \n, A
	StringReplace, obj, obj, % Chr(12), \f, A
	StringReplace, obj, obj, `r, \r, A
	StringReplace, obj, obj, ", \", A
	StringReplace, obj, obj, /, \/, A
	While RegexMatch( obj, "[^\x20-\x7e]", key )
	{
		str := Asc( key )
		val := "\u" . Chr( ( ( str >> 12 ) & 15 ) + ( ( ( str >> 12 ) & 15 ) < 10 ? 48 : 55 ) )
				. Chr( ( ( str >> 8 ) & 15 ) + ( ( ( str >> 8 ) & 15 ) < 10 ? 48 : 55 ) )
				. Chr( ( ( str >> 4 ) & 15 ) + ( ( ( str >> 4 ) & 15 ) < 10 ? 48 : 55 ) )
				. Chr( ( str & 15 ) + ( ( str & 15 ) < 10 ? 48 : 55 ) )
		StringReplace, obj, obj, % key, % val, A
	}
	return """" obj """"
} ; json_fromobj( obj )

BuildJson(obj) 
{
    str := "" , array := true
    for k in obj {
        if (k == A_Index)
            continue
        array := false
        break
    }
    for a, b in obj
        str .= (array ? "" : """" a """: ") . (IsObject(b) ? BuildJson(b) : IsNumber(b) ? b : """" b """") . ", "	
    str := RTrim(str, " ,")
    return (array ? "[" str "]" : "{" str "}")
}

ParseJson(jsonStr)
{
    SC := ComObjCreate("ScriptControl") 
    SC.Language := "JScript"
    ComObjError(false)
    jsCode =
    (
    function arrangeForAhkTraversing(obj){
        if(obj instanceof Array){
            for(var i=0 ; i<obj.length ; ++i)
                obj[i] = arrangeForAhkTraversing(obj[i]) ;
            return ['array',obj] ;
        }else if(obj instanceof Object){
            var keys = [], values = [] ;
            for(var key in obj){
                keys.push(key) ;
                values.push(arrangeForAhkTraversing(obj[key])) ;
            }
            return ['object',[keys,values]] ;
        }else
            return [typeof obj,obj] ;
    }
    )
    SC.ExecuteStatement(jsCode "; obj=" jsonStr)
    return convertJScriptObjToAhks( SC.Eval("arrangeForAhkTraversing(obj)") )
}

/*!
    Function: convertJScriptObjToAhks(jsObj)
        Used by ParseJson()
*/
convertJScriptObjToAhks(jsObj)
{
    if(jsObj[0]="object"){
        obj := {}, keys := jsObj[1][0], values := jsObj[1][1]
        loop % keys.length
            obj[keys[A_INDEX-1]] := convertJScriptObjToAhks( values[A_INDEX-1] )
        return obj
    }else if(jsObj[0]="array"){
        array := []
        loop % jsObj[1].length
            array.insert(convertJScriptObjToAhks( jsObj[1][A_INDEX-1] ))
        return array
    }else
        return jsObj[1]
}

/*!
    Function: IsNumber(Num)
        Checks if Num is a number.

    Returns:
        True if Num is a number, false if not
*/
IsNumber(Num)
{
    if Num is number
        return true
    else
        return false
}