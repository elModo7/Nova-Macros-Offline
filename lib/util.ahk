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