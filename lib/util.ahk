; Since VerCompare is > 1.1.36.1 I will use this to keep compatibility with lower versions of AHK
VerCmp(V1, V2) {           ; VerCmp() for Windows by SKAN on D35T/D37L @ tiny.cc/vercmp 
Return ( ( V1 := Format("{:04X}{:04X}{:04X}{:04X}", StrSplit(V1 . "...", ".",, 5)*) )
       < ( V2 := Format("{:04X}{:04X}{:04X}{:04X}", StrSplit(V2 . "...", ".",, 5)*) ) )
       ? -1 : ( V2<V1 ) ? 1 : 0
}

urlDownloadToVar(url,raw:=0,userAgent:="",headers:=""){
	if (!regExMatch(url,"i)https?://"))
		url:="https://" url
	try {
		hObject:=comObjCreate("WinHttp.WinHttpRequest.5.1")
		hObject.open("GET",url)
		if (userAgent)
			hObject.setRequestHeader("User-Agent",userAgent)
		if (isObject(headers)) {
			for i,a in headers {
				hObject.setRequestHeader(i,a)
			}
		}
		hObject.send()
		return raw?hObject.responseBody:hObject.responseText
	} catch e
		return % e.message
}

URLToVar(URL)
{
    ComObjError(0)
    WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    WebRequest.Open("GET", URL)
    WebRequest.Send()
    Return WebRequest.ResponseText()
}

AHK_ICONCLICKCHECK()
{
	global AHK_ICONCLICKCOUNT
	if  (AHK_ICONCLICKCOUNT = 1)		; LEFT CLK
	{
		;~ Menu, LeftClickMenu, Show
	}
	else if (AHK_ICONCLICKCOUNT = 2)	; LEFT DBCLK
	{
		gosub, ToggleHide
	}
	return 0
}

AHK_ICONCLICKNOTIFY(wParam,lParam)
{
	global AHK_ICONCLICKCOUNT
	if (lParam = 0x201)
	{
		AHK_ICONCLICKCOUNT := 1
		SetTimer, AHK_ICONCLICKCHECK, -200
	}
	else if (lParam = 0x203)
	{
		AHK_ICONCLICKCOUNT := 2
	}
	else if (lParam = 0x205)			; RIGHT CLK
	{
		Menu, Tray, Show			; launch standard menu
		;~ Menu, RightClickMenu, Show	; or a custom one
	}
	else if (lParam = 0x208)			; MIDDLE CLK
	{
		;~ Menu, MiddleClickMenu, Show
	}
	return 0
}