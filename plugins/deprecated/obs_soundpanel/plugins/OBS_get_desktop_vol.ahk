; Obtener Volumen escritorio
#NoEnv
#NoTrayIcon
#SingleInstance, Force
global volEscritorio, muteEscritorio
SetBatchLines, -1
new getDesktopVol("ws://127.0.0.1:4444")
return

class getDesktopVol extends WebSocket
{
	OnOpen(Event)
	{
		Sleep, 100
		Data = {"source": "Audio del escritorio","request-type": "GetVolume","message-id": "123"}
		this.Send(Data)
	}
	
	OnMessage(Event)
	{
		volEscritorio := SubStr(Event.Data, InStr(Event.Data, "volume")+9, 4)
		muteEscritorio := SubStr(Event.Data, InStr(Event.Data, "mute")+8, 1) = "t" ? 1 : 0 ; f/t false/true
		MsgBox, Vol: %volEscritorio%`nMuted: %muteEscritorio%
		MsgBox, % Event.Data
		Sleep, 2000
		this.Close()
	}
	
	OnClose(Event)
	{
		this.Disconnect()
		ExitApp
	}
	
	__Delete()
	{
		ExitApp
	}
}

; ************************
; WEB SOCKET STUFF
; ************************
class WebSocket
{
	__New(WS_URL)
	{
		static wb
		
		; Create an IE instance
		Gui, +hWndhOld
		Gui, New, +hWndhWnd
		this.hWnd := hWnd
		Gui, Add, ActiveX, vWB, Shell.Explorer
		Gui, %hOld%: Default
		
		; Write an appropriate document
		WB.Navigate("about:<!DOCTYPE html><meta http-equiv='X-UA-Compatible'"
		. "content='IE=edge'><body></body>")
		while (WB.ReadyState < 4)
			sleep, 50
		this.document := WB.document
		
		; Add our handlers to the JavaScript namespace
		this.document.parentWindow.ahk_savews := this._SaveWS.Bind(this)
		this.document.parentWindow.ahk_event := this._Event.Bind(this)
		this.document.parentWindow.ahk_ws_url := WS_URL
		
		; Add some JavaScript to the page to open a socket
		Script := this.document.createElement("script")
		Script.text := "ws = new WebSocket(ahk_ws_url);`n"
		. "ws.onopen = function(event){ ahk_event('Open', event); };`n"
		. "ws.onclose = function(event){ ahk_event('Close', event); };`n"
		. "ws.onerror = function(event){ ahk_event('Error', event); };`n"
		. "ws.onmessage = function(event){ ahk_event('Message', event); };"
		this.document.body.appendChild(Script)
	}
	
	; Called by the JS in response to WS events
	_Event(EventName, Event)
	{
		this["On" EventName](Event)
	}
	
	; Sends data through the WebSocket
	Send(Data)
	{
		this.document.parentWindow.ws.send(Data)
	}
	
	; Closes the WebSocket connection
	Close(Code:=1000, Reason:="")
	{
		this.document.parentWindow.ws.close(Code, Reason)
	}
	
	; Closes and deletes the WebSocket, removing
	; references so the class can be garbage collected
	Disconnect()
	{
		if this.hWnd
		{
			this.Close()
			Gui, % this.hWnd ": Destroy"
			this.hWnd := False
		}
	}
}
