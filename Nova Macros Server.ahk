; OS Version ...: Windows 10 (Should work with Win7, maybe WinXP)
;@Ahk2Exe-SetName Nova Macros Client Online
;@Ahk2Exe-SetDescription Nova Macros Server for remote control
;@Ahk2Exe-SetVersion 0.4.3
;@Ahk2Exe-SetCopyright Copyright (c) 2025`, elModo7
;@Ahk2Exe-SetOrigFilename Nova Macros Server.exe
; INITIALIZE
; *******************************
#SingleInstance,Force
SetBatchLines, -1
#NoEnv
#Persistent
global versionNumber := "0.4.3"
global clientVersion := versionNumber " - elModo7 / VictorDevLog " A_YYYY
#Include <Socket>
#Include <JSON>
#Include <MD5>
#Include <SplashScreen>
#Include <aboutScreen>
rutaSplash = ./resources/img/splash.png
SplashScreen(rutaSplash, 3000, 545, 160, 0, 0, true)
GuiControl, splashScreen:, splashTxt, % "Reading config..."

if(!FileExist("./conf/server_config.json"))
{
	conf := {}
	conf.builtin_ahk := 1
	conf.port := 7778
	conf.totalResourceSize := 0
	conf.resourcePackMD5 := "MD5HashGoesHere"
    conf.resourceSharePort := 7779
    conf.startWithWindows := 1
	gosub, guardarConfig
}
FileRead, conf, ./conf/server_config.json
global conf := ParseJson(conf)
gosub, guardarConfigShared

; TRAY MENU
; *******************************
Menu, tray, NoStandard
Menu, tray, Add, Use built-in AHK, toggleBuiltInAhk
Menu, tray, Add, Update Resource Pack Now, 7zImageButtons
Menu tray, Icon, Update Resource Pack Now, .\resources\img\ico\windows\compressed_folder.ico
Menu, tray, Add, Set custom Port, setPort
Menu tray, Icon, Set custom Port, .\resources\img\ico\windows\network2.ico
Menu, tray, add, Open Nova Macros Folder, openNovaMacrosFolder
Menu, tray, Icon, Open Nova Macros Folder, .\resources\img\ico\windows\folder.ico
Menu, tray, Add, Run on Startup, startWithWindows
Menu tray, Icon, Run on Startup, .\resources\img\ico\windows\window_possition.ico
Menu, tray, add
Menu, tray, add, % "v" clientVersion, showAboutScreen
Menu, tray, Icon, % "v" clientVersion, .\resources\img\ico\windows\info.ico
Menu, tray, Add, Restart Server, restart
Menu tray, Icon, Restart Server, .\resources\img\ico\windows\refresh.ico
Menu, tray, add, Exit, Exit
Menu tray, Icon, Exit, .\resources\img\ico\windows\close3.ico
if(conf.builtin_ahk)
{
	Menu tray, Check, Use built-in AHK
}
else
{
	Menu tray, UnCheck, Use built-in AHK
}
if(conf.startWithWindows)
{
	Menu, tray, Check, Run on Startup
}
else
{
	Menu, tray, Uncheck, Run on Startup
}

; Create zip for sharing to clients
gosub, 7zImageButtons
gosub, startWebServer

; Start Networking
global myTcp := new SocketTCP()
myTcp.bind("0.0.0.0", conf.port)
myTcp.listen() ; Escucha
myTcp.onAccept := Func("OnTCPAccept")
Gui, SplashScreen:Destroy
Return

toggleBuiltInAhk:
	if(conf.builtin_ahk)
	{
		conf.builtin_ahk := 0
		Menu tray, UnCheck, Use built-in AHK
	}
	else
	{
		conf.builtin_ahk := 1
		Menu tray, Check, Use built-in AHK
	}
	gosub, guardarConfig
return

guardarConfig:
	FileDelete, ./conf/server_config.json
	FileAppend, % JSON_Beautify(BuildJson(conf)), ./conf/server_config.json
return

guardarConfigShared:
	FileRead, shared_conf, ./resources/shared/resourcePack_info.txt
	FileRead, client_conf, ./conf/config.json
	client_conf := ParseJson(client_conf)
	shared_conf := ParseJson(shared_conf)
	shared_conf.folderButtons := client_conf.folderButtons
	FileDelete, ./resources/shared/resourcePack_info.txt
	FileAppend, % JSON_Beautify(BuildJson(shared_conf)), ./resources/shared/resourcePack_info.txt
return

OnExit, Exit
Exit:
	gosub, killPreviousInstance
ExitApp

MoverVentana:
    PostMessage, 0xA1, 2,,, A
Return

OnTCPRecvServer(this)
{
    global Client
    data := ParseJson(this.RecvText())
    try
    {
        Client.sendText(data.BotonVisual)
        if(FileExist(data.FicheroEjecutar))
        {
            if(conf.builtin_ahk)
			{
                Run, % A_ScriptDir "\lib\autohotkey.exe " data.FicheroEjecutar
			}
			else
			{
                Run, % data.FicheroEjecutar
			}
        }
    }
}

OnTCPAccept(this)
{
    global Client
    Client := this.accept()
    Client.onRecv := func("OnTCPRecvServer")
    Client.sendText("Nova Macros Server")
}

7zImageButtons:
    Run, % """" A_ScriptDir "/lib/autohotkey.exe"" " """" A_ScriptDir """/lib/compress_and_md5.ahk""", A_ScriptDir
return

restart:
    Reload

FileMD5(filename)
{
    return CalcFileHash(filename, 0x8003, 64 * 1024)
}

setPort:
    InputBox, port, Port to Use, Insert Port to use for the server:
    if(Trim(port) != "" && Trim(port) >= 1 && Trim(port) <= 65535)
    {
		InputBox, resourceSharePort, File Port to Use, Insert Port to use for button images:
		if(Trim(resourceSharePort) != "" && Trim(resourceSharePort) >= 1 && Trim(resourceSharePort) <= 65535 && Trim(port) != Trim(resourceSharePort))
		{
			conf.port := Trim(port)
			conf.resourceSharePort := Trim(resourceSharePort)
			gosub, guardarConfig
		}
		else
		{
			MsgBox, You didn't set a port or it was invalid (valid range 1-65535)!`nAlso make sure that file port and server port are different!
		}
    }
    else
    {
        MsgBox, You didn't set a port or it was invalid (valid range 1-65535)!
    }
return

startWebServer:
	gosub, killPreviousInstance
	Run, % "./lib/httpsrv.exe -d 0 -v 0 -p " conf.resourceSharePort " -r """ A_ScriptDir "\resources\shared""",, Hide
return

killPreviousInstance:
	process = httpsrv.exe
	Process, Exist, %process%
	if	pid :=	ErrorLevel
	{
		Loop
		{
			WinClose, ahk_pid %pid%, , 5
			if	ErrorLevel
				Process, Close, %pid%
			Process, Exist, %process%
		}	Until	!pid :=	ErrorLevel
	}
return

startWithWindows:
	conf.startWithWindows := !conf.startWithWindows
	gosub, guardarConfig
	if(conf.startWithWindows)
	{
		FileCreateShortcut, %A_ScriptFullPath%, %A_AppData%\Microsoft\Windows\Start Menu\Programs\Startup\Nova Macros Server.lnk, %A_ScriptDir%, Nova Macros Server Software
		Menu, tray, Check, Run on Startup
	}
	else
	{
		FileDelete, %A_AppData%\Microsoft\Windows\Start Menu\Programs\Startup\Nova Macros Server.lnk
		Menu, tray, Uncheck, Run on Startup
	}
return

showAboutScreen:
	showAboutScreen("Nova Macros Server v" versionNumber, "A multi-purpose RPC server for triggering scripts remotely on the running host via RAW TCP sockets.")
return

openNovaMacrosFolder:
	Run, % A_ScriptDir
return