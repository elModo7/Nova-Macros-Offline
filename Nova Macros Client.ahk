; OS Version ...: Windows 10+ (Previous versions tested working on Win7)
; Requires AutoHotkeyU32
;@Ahk2Exe-SetName Nova Macros Client
;@Ahk2Exe-SetDescription Nova Macros for TouchScreen and Remote Control
;@Ahk2Exe-SetVersion 3.7.5
;@Ahk2Exe-SetCopyright Copyright (c) 2025`, elModo7 - VictorDevLog
;@Ahk2Exe-SetOrigFilename Nova Macros Client.exe
; INITIALIZE
; *******************************
/*
TODO:
- Reactive window configurer (Program Selector, Page Selector)
- Más funciones de OBS
- BtnDescriptions (label con texto de descripción (texto, color, transparencia, fontweight))

REQUIERES:
- Windows 10
- AutoHotkey U32 (las librerías JSON y them.dll no funcionan en U64)
- Compilar sin MPRESS, se pierde compatibilidad con USkin.dll

DISCARDED:
- Volver a la carpeta anterior y volver a la raíz si se pulsa p.ej control

LATEST CHANGES:
- OBS Websocket Compat 4.x -> 5.X
- Improve online mode

COMMENTS:
- This script is one of my very first AutoHotkey scripts (Jun 2017), it can be improved A LOT, code quality wise (starting from keeping it consistent with a single language instead of Spanglish). However, I use it on a day to day basis and it is "robust enough" and convenient that I make heavy use of it, even above any other Hotkey, Dedicated Keyboard, Macro Deck, StreamDock or Android solutions I currently have purchased.
- It packs a few libraries of my own and a few "hacky" resources. While doing it I learned A LOT on GUI optimisations such as double buffering, temporal GUI freezing, image in-memory caching for quick updates, autoupdating scripts, Config, Sockets, WebSockets, OSC protocol, theming, GDI, Win32 API, HTTP OBJ, encryption, base 64 resources, queuing...
- It gave birth to many snippets for other projects such as OBS Control via WebSockets, OBSBOT Gimbal Webcams control via OSC, SplashScreen and About generic GUI snippets, ClientUpdater lib, Installer Generator, Obfuscation (removed), Online Licensing (removed).
*/
#NoEnv
#Persistent
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows, On
CoordMode,Mouse,Screen
SetBatchLines, -1
#Include, <nm_msg>
#Include, <JSON>
#Include <SplashScreen>
#Include <Socket>
#Include <util>
#Include <client_updater>
#Include <aboutScreen>
rutaSplash = ./resources/img/splash.png
global ClientVersionNumber := "3.7.5"
global ClientVersion := ClientVersionNumber " - elModo7 / VictorDevLog " A_YYYY
SplashScreen(rutaSplash, 3000, 545, 160, 0, 0, true)
global EsVisible = true
global EnCarpeta = false
global CarpetaBoton, PaginaCarpeta, BotonActivo, BotonAPulsar, windowHandler, IpTxt, PortTxt, OnlineChk, AHK_ICONCLICKCOUNT, server_config, previousActiveProcess
global RutaBoton1, RutaBoton2, RutaBoton3, RutaBoton4, RutaBoton5, RutaBoton6, RutaBoton7, RutaBoton8, RutaBoton9, RutaBoton10, RutaBoton11, RutaBoton12, RutaBoton13, RutaBoton14, RutaBoton15
global feedbackEjecucion := []
global NumeroPagina := 0
global serverFound := 0
global reactiveWindow := 0
global MsgBoxBtn1, MsgBoxBtn2, MsgBoxBtn3, MsgBoxBtn4
SkinForm(Apply, A_ScriptDir . "\lib\script_generator\lib\them.dll", A_ScriptDir . "\lib\script_generator\lib\tm")
OnExit, GetOut
FileCreateDir, conf
global btnPics := {}
GuiControl, splashScreen:, splashTxt, % "Reading config..."
contextcolor(2) ;0=Default ;1=AllowDark ;2=ForceDark ;3=ForceLight ;4=Max

if(!FileExist("./conf/config.json"))
{
	GuiControl, splashScreen:, splashTxt, % "Config not found, creating new config..."
	conf := {}
	conf.programFolder["obs64.exe"] := "obs"
	conf.programFolder["SciTE.exe"] := "ahk"
	conf.scriptEditorPath := "C:\Program Files\AutoHotkey\SciTE\SciTE.exe"
	conf.ip := "127.0.0.1"
	conf.port := "7778"
	conf.resourcesPort := "7779"
	conf.extension := "ahk"
	conf.folderButtons := {"5":"OBS"}
	conf.folderButtons.1 := "UtilesStream"
	conf.folderButtons.2 := "SonidosOBS"
	conf.folderButtons.3 := "VoiceMod"
	conf.folderButtons.6 := "App"
	conf.folderButtons.7 := "Game"
	conf.folderButtons.4 := "Magix"
	conf.folderButtons.8 := "AHK"
	conf.pantalla_Mitad_X := A_ScreenWidth / 2
	conf.pantalla_Mitad_Y := A_ScreenHeight / 2
	conf.x_Inicial := 960
	conf.y_Inicial := 1080
	conf.moverRatonAlPulsarBoton := 1
	conf.enviarAltTabAlPulsarBoton := 1
	conf.cargaProgresivaIconos := 0
	conf.siempreVisible := 0
	conf.miniClient := 0
	conf.online := 0
	conf.builtin_ahk := 1
	conf.reactiveWindow := 0
	conf.lookForUpdates := 1
	gosub, guardarConfig
}

gosub, loadConfig
GuiControl, splashScreen:, splashTxt, % "Creating Tray & Context Menus..."

; dark mode menu options
contextcolor(color:=2) ; change the number here from the list above if you want light mode
{
	static uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
	static SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
	static FlushMenuThemes := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
	DllCall(SetPreferredAppMode, "int", color)
	DllCall(FlushMenuThemes)
}
; TRAY MENU
; *******************************
Menu, tray, NoStandard
Menu, tray, tip, Nova Macros Client v%ClientVersionNumber%
Menu, tray, add, Hide, ToggleHide
Menu tray, Icon, Hide, .\resources\img\ico\windows\cut_visibility.ico
Menu, tray, add, Set Editor Path, CambiarRutaEditor
Menu tray, Icon, Set Editor Path, .\resources\img\ico\windows\edit2.ico
Menu tray, add, Set Start Window Possition, setStartPossition
Menu tray, Icon, Set Start Window Possition, .\resources\img\ico\windows\window_possition.ico
Menu tray, add, Backup Nova Macros Folder (*.7z), generateBackup
Menu tray, Icon, Backup Nova Macros Folder (*.7z), .\resources\img\ico\windows\compressed_folder.ico
Menu tray, add, Open Nova Macros Folder, openNovaMacrosFolder
Menu tray, Icon, Open Nova Macros Folder, .\resources\img\ico\windows\folder.ico
Menu, tray, add
Menu, tray, add, Network Settings, crearGuiNetworkSettings
Menu tray, Icon, Network Settings, .\resources\img\ico\windows\network2.ico
Menu, tray, add
Menu LookForUpdatesMenu, Add, On Boot, lookForUpdatesOnBootLabel
Menu LookForUpdatesMenu, Icon, On Boot, .\resources\img\ico\windows\look_for_updates.ico
Menu LookForUpdatesMenu, Add, Now, lookForUpdatesLabel
Menu LookForUpdatesMenu, Icon, Now, .\resources\img\ico\windows\download.ico
Menu tray, Add, Look for Updates, :LookForUpdatesMenu
Menu tray, Icon, Look for Updates, .\resources\img\ico\windows\refresh.ico

Menu, tray, add, % "v" ClientVersion, showAboutScreen
Menu tray, Icon, % "v" ClientVersion, .\resources\img\ico\windows\info.ico
;~ Menu, tray, disable, % "v" ClientVersion
Menu, tray, add, Exit, Exit
Menu tray, Icon, Exit, .\resources\img\ico\windows\close3.ico

if(conf.lookForUpdates)
	Menu LookForUpdatesMenu, Check, On Boot
else
	Menu LookForUpdatesMenu, UnCheck, On Boot

; CONTEXT MENU GENERICO
; *******************************
Menu ContextMenuGenerico, Add, Always on Top, SiempreVisible
if(conf.siempreVisible)
{
	Menu ContextMenuGenerico, Check, Always on Top
}
else
{
	Menu ContextMenuGenerico, UnCheck, Always on Top
}

Menu ContextMenuGenerico, Add, Center Mouse after Activation, MoverRatonAlPulsarBotonToggle
if(conf.moverRatonAlPulsarBoton)
{
	Menu ContextMenuGenerico, Check, Center Mouse after Activation
}
else
{
	Menu ContextMenuGenerico, UnCheck, Center Mouse after Activation
}
Menu ContextMenuGenerico, Add, Send Alt+Tab after Activation, enviarAltTabAlPulsarBotonToggle
if(conf.enviarAltTabAlPulsarBoton)
{
	Menu ContextMenuGenerico, Check, Send Alt+Tab after Activation
}
else
{
	Menu ContextMenuGenerico, UnCheck, Send Alt+Tab after Activation
}
Menu ContextMenuGenerico, Add, Progressive Icon Loading, cargaProgresivaIconosToggle
if(conf.cargaProgresivaIconos)
{
	Menu ContextMenuGenerico, Check, Progressive Icon Loading
}
else
{
	Menu ContextMenuGenerico, UnCheck, Progressive Icon Loading
}
Menu ContextMenuGenerico, Add, Mini Client, CambiarDimensionesCliente
Menu ContextMenuGenerico, UnCheck, Mini Client
Menu ContextMenuGenerico, Add, Set Start Window Possition, setStartPossition
Menu ContextMenuGenerico, UnCheck, Set Start Window Possition
Menu ContextMenuGenerico, Add, Use built-in AHK, toggleBuiltInAhk
if(conf.builtin_ahk)
{
	Menu ContextMenuGenerico, Check, Use built-in AHK
}
else
{
	Menu ContextMenuGenerico, UnCheck, Use built-in AHK
}
Menu ContextMenuGenerico, Add, Minimize to tray (Hide), ToggleHide
Menu ContextMenuGenerico, Add, Reactive Pages, changeReactiveSetting
if(conf.reactiveWindow)
{
	Menu ContextMenuGenerico, Check, Reactive Pages
}
else
{
	Menu ContextMenuGenerico, UnCheck, Reactive Pages
}
Menu ContextMenuGenerico, Add, Bind this folder to a program or window, bindFolderToProgramOrWindow
Menu ContextMenuGenerico, Disable, Bind this folder to a program or window

; CONTEXT MENU BOTONES
; *******************************
Menu scriptGenerator, Add, Run File, ScriptGenerator_RunFile
Menu scriptGenerator, Icon, Run File, shell32.dll, 25
Menu scriptGenerator, Add, Run Cmd, ScriptGenerator_RunCmd
Menu scriptGenerator, Icon, Run Cmd, .\resources\img\ico\windows\powershell.ico
Menu scriptGenerator, Add, Send Text, ScriptGenerator_SendText
Menu scriptGenerator, Icon, Send Text, shell32.dll, 71
Menu scriptGenerator, Add, Hotkey - Macro, ScriptGenerator_Hotkey
Menu scriptGenerator, Icon, Hotkey - Macro, imageres.dll, 174
Menu MultimediaFunctions, Add, Play / Pause, ScriptGenerator_Multimedia_PlayPause
Menu MultimediaFunctions, Icon, Play / Pause, imageres.dll, 62
Menu MultimediaFunctions, Add, Stop, ScriptGenerator_Multimedia_Stop
Menu MultimediaFunctions, Icon, Stop, imageres.dll, 62
Menu MultimediaFunctions, Add, Previous, ScriptGenerator_Multimedia_Previous
Menu MultimediaFunctions, Icon, Previous, imageres.dll, 62
Menu MultimediaFunctions, Add, Next, ScriptGenerator_Multimedia_Next
Menu MultimediaFunctions, Icon, Next, imageres.dll, 62
Menu MultimediaFunctions, Add, Volume +, ScriptGenerator_Multimedia_MoreVolume
Menu MultimediaFunctions, Icon, Volume +, imageres.dll, 62
Menu MultimediaFunctions, Add, Volume -, ScriptGenerator_Multimedia_LessVolume
Menu MultimediaFunctions, Icon, Volume -, imageres.dll, 62
Menu MultimediaFunctions, Add, Mute / Unmute, ScriptGenerator_Multimedia_Mute
Menu MultimediaFunctions, Icon, Mute / Unmute, imageres.dll, 62
Menu QuickActionsMenu, Add, Close Window, ScriptGenerator_QuickActions_CloseWindow
Menu QuickActionsMenu, Icon, Close Window, .\resources\img\ico\windows\close3.ico
Menu QuickActionsMenu, Add, Maximize Window, ScriptGenerator_QuickActions_Maximize
Menu QuickActionsMenu, Icon, Maximize Window, imageres.dll, 287
Menu QuickActionsMenu, Add, Minimize Window, ScriptGenerator_QuickActions_Minimize
Menu QuickActionsMenu, Icon, Minimize Window, imageres.dll, 17
Menu QuickActionsMenu, Add, Show Desktop, ScriptGenerator_QuickActions_ShowDesktop
Menu QuickActionsMenu, Icon, Show Desktop, imageres.dll, 106
Menu QuickActionsMenu, Add, New Explorer Window, ScriptGenerator_QuickActions_NewExplorer
Menu QuickActionsMenu, Icon, New Explorer Window, imageres.dll, 5
Menu QuickActionsMenu, Add, New Folder, ScriptGenerator_QuickActions_NewFolder
Menu QuickActionsMenu, Icon, New Folder, .\resources\img\ico\windows\folder.ico
Menu QuickActionsMenu, Add, Quick Rename File, ScriptGenerator_QuickActions_QuickRename
Menu QuickActionsMenu, Icon, Quick Rename File, shell32.dll, 134
Menu QuickActionsMenu, Add, Lock PC, ScriptGenerator_QuickActions_LockPC
Menu QuickActionsMenu, Icon, Lock PC, shell32.dll, 45
Menu QuickActionsMenu, Add, Shutdown PC, ScriptGenerator_QuickActions_Shutdown
Menu QuickActionsMenu, Icon, Shutdown PC, shell32.dll, 28
Menu QuickActionsMenu, Add, System Info, ScriptGenerator_QuickActions_SystemInfo
Menu QuickActionsMenu, Icon, System Info, shell32.dll, 24
Menu QuickActionsMenu, Add, System FULL Info, ScriptGenerator_QuickActions_FullSystemInfo
Menu QuickActionsMenu, Icon, System FULL Info, shell32.dll, 22
Menu QuickActionsMenu, Add, cmd.exe, ScriptGenerator_QuickActions_Cmd
Menu QuickActionsMenu, Icon, cmd.exe, .\resources\img\ico\windows\cmd.ico
Menu QuickActionsMenu, Add, PowerShell, ScriptGenerator_QuickActions_PowerShell
Menu QuickActionsMenu, Icon, PowerShell, .\resources\img\ico\windows\powershell.ico
Menu QuickActionsMenu, Add, Take Screenshot, ScriptGenerator_QuickActions_ScreenShot
Menu QuickActionsMenu, Icon, Take Screenshot, imageres.dll, 68
Menu QuickActionsMenu, Add, Snip img from screen, ScriptGenerator_QuickActions_SnipImage
Menu QuickActionsMenu, Icon, Snip img from screen, imageres.dll, 17
Menu QuickActionsMenu, Add, Windows Gaming Panel, ScriptGenerator_QuickActions_GamePanel
Menu QuickActionsMenu, Icon, Windows Gaming Panel, imageres.dll, 305
Menu QuickActionsMenu, Add, Windows Emoji Panel, ScriptGenerator_QuickActions_EmojiPanel
Menu QuickActionsMenu, Icon, Windows Emoji Panel, imageres.dll, 205
Menu WebBrowserCommands, Add, Next Tab, ScriptGenerator_WebBrowser_NextTab
Menu WebBrowserCommands, Icon, Next Tab, shell32.dll, 15
Menu WebBrowserCommands, Add, Previous Tab, ScriptGenerator_WebBrowser_PreviousTab
Menu WebBrowserCommands, Icon, Previous Tab, shell32.dll, 15
Menu WebBrowserCommands, Add, New Tab, ScriptGenerator_WebBrowser_NewTab
Menu WebBrowserCommands, Icon, New Tab, shell32.dll, 15
Menu WebBrowserCommands, Add, New Window, ScriptGenerator_WebBrowser_NewWindow
Menu WebBrowserCommands, Icon, New Window, shell32.dll, 15
Menu WebBrowserCommands, Add, Close Tab, ScriptGenerator_WebBrowser_CloseTab
Menu WebBrowserCommands, Icon, Close Tab, shell32.dll, 15
Menu WebBrowserCommands, Add, Restore Closed Tab, ScriptGenerator_WebBrowser_RestoreTab
Menu WebBrowserCommands, Icon, Restore Closed Tab, shell32.dll, 15
Menu WebBrowserCommands, Add, Chrome Private Window (NEW), ScriptGenerator_WebBrowser_ChromePrivWindow
Menu WebBrowserCommands, Icon, Chrome Private Window (NEW), shell32.dll, 15
Menu FunctionKeysMenu, Add, F13, ScriptGenerator_FunctionKeys_F13
Menu FunctionKeysMenu, Icon, F13, imageres.dll, 174
Menu FunctionKeysMenu, Add, F14, ScriptGenerator_FunctionKeys_F14
Menu FunctionKeysMenu, Icon, F14, imageres.dll, 174
Menu FunctionKeysMenu, Add, F15, ScriptGenerator_FunctionKeys_F15
Menu FunctionKeysMenu, Icon, F15, imageres.dll, 174
Menu FunctionKeysMenu, Add, F16, ScriptGenerator_FunctionKeys_F16
Menu FunctionKeysMenu, Icon, F16, imageres.dll, 174
Menu FunctionKeysMenu, Add, F17, ScriptGenerator_FunctionKeys_F17
Menu FunctionKeysMenu, Icon, F17, imageres.dll, 174
Menu FunctionKeysMenu, Add, F18, ScriptGenerator_FunctionKeys_F18
Menu FunctionKeysMenu, Icon, F18, imageres.dll, 174
Menu FunctionKeysMenu, Add, F19, ScriptGenerator_FunctionKeys_F19
Menu FunctionKeysMenu, Icon, F19, imageres.dll, 174
Menu FunctionKeysMenu, Add, F20, ScriptGenerator_FunctionKeys_F20
Menu FunctionKeysMenu, Icon, F20, imageres.dll, 174
Menu FunctionKeysMenu, Add, F21, ScriptGenerator_FunctionKeys_F21
Menu FunctionKeysMenu, Icon, F21, imageres.dll, 174
Menu FunctionKeysMenu, Add, F22, ScriptGenerator_FunctionKeys_F22
Menu FunctionKeysMenu, Icon, F22, imageres.dll, 174
Menu FunctionKeysMenu, Add, F23, ScriptGenerator_FunctionKeys_F23
Menu FunctionKeysMenu, Icon, F23, imageres.dll, 174
Menu FunctionKeysMenu, Add, F24, ScriptGenerator_FunctionKeys_F24
Menu FunctionKeysMenu, Icon, F24, imageres.dll, 174
Menu OBSFunctions, Add, Set Scene, ScriptGenerator_OBS_SetScene
Menu OBSFunctions, Icon, Set Scene, resources\img\ico\OBS.ico
Menu OBSFunctions, Add, Hide/Show Source, ScriptGenerator_OBS_HideShowSource
Menu OBSFunctions, Icon, Hide/Show Source, resources\img\ico\OBS.ico
Menu OBSFunctions, Add, Start Recording, ScriptGenerator_OBS_Record
Menu OBSFunctions, Icon, Start Recording, resources\img\ico\OBS.ico
Menu OBSFunctions, Add, Stop Recording, ScriptGenerator_OBS_StopRecord
Menu OBSFunctions, Icon, Stop Recording, resources\img\ico\OBS.ico
Menu OBSFunctions, Add, Pause Recording, ScriptGenerator_OBS_PauseRecord
Menu OBSFunctions, Icon, Pause Recording, resources\img\ico\OBS.ico
Menu OBSFunctions, Add, Resume Recording, ScriptGenerator_OBS_ResumeRecord
Menu OBSFunctions, Icon, Resume Recording, resources\img\ico\OBS.ico
Menu OBSFunctions, Add, Mute/Unmute Source, ScriptGenerator_OBS_MuteUnmuteSource
Menu OBSFunctions, Icon, Mute/Unmute Source, resources\img\ico\OBS.ico
Menu OBSFunctions, Add, Show current Scene, ScriptGenerator_OBS_ShowCurrentScene
Menu OBSFunctions, Icon, Show current Scene, resources\img\ico\OBS.ico
Menu OBSFunctions, Add, Sound Pannel, ScriptGenerator_OBS_SoundPannel
Menu OBSFunctions, Icon, Sound Pannel, resources\img\ico\OBS.ico

Menu OBSBOTFunctions, Add, Sleep Webcam, ScriptGenerator_OBSBOT_Sleep
Menu OBSBOTFunctions, Icon, Sleep Webcam, resources\img\ico\obsbot.ico
Menu OBSBOTFunctions, Add, Wake Webcam, ScriptGenerator_OBSBOT_Wake
Menu OBSBOTFunctions, Icon, Wake Webcam, resources\img\ico\obsbot.ico
Menu OBSBOTFunctions, Add, Set Zoom, ScriptGenerator_OBSBOT_SetZoom
Menu OBSBOTFunctions, Icon, Set Zoom, resources\img\ico\obsbot.ico
Menu OBSBOTFunctions, Add, Start Recording, ScriptGenerator_OBSBOT_StartRecording
Menu OBSBOTFunctions, Icon, Start Recording, resources\img\ico\obsbot.ico
Menu OBSBOTFunctions, Add, Stop Recording, ScriptGenerator_OBSBOT_StopRecording
Menu OBSBOTFunctions, Icon, Stop Recording, resources\img\ico\obsbot.ico
Menu OBSBOTFunctions, Add, Take Photo, ScriptGenerator_OBSBOT_TakePhoto
Menu OBSBOTFunctions, Icon, Take Photo, resources\img\ico\obsbot.ico
Menu OBSBOTFunctions, Add, Reset Gimbal, ScriptGenerator_OBSBOT_ResetGimbal
Menu OBSBOTFunctions, Icon, Reset Gimbal, resources\img\ico\obsbot.ico
Menu OBSBOTFunctions, Add, Set FOV, ScriptGenerator_OBSBOT_SetFOV
Menu OBSBOTFunctions, Icon, Set FOV, resources\img\ico\obsbot.ico
Menu OBSBOTFunctions, Add, Set Mirror, ScriptGenerator_OBSBOT_Mirror
Menu OBSBOTFunctions, Icon, Set Mirror, resources\img\ico\obsbot.ico
Menu OBSBOTFunctions, Add, Set Tracking Mode, ScriptGenerator_OBSBOT_TrackingMode
Menu OBSBOTFunctions, Icon, Set Tracking Mode, resources\img\ico\obsbot.ico
Menu OBSBOTFunctions, Add, Set AI Lock / Unlock, ScriptGenerator_OBSBOT_AILock
Menu OBSBOTFunctions, Icon, Set AI Lock / Unlock, resources\img\ico\obsbot.ico
Menu OBSBOTFunctions, Add, Set AI Mode, ScriptGenerator_OBSBOT_AIMode
Menu OBSBOTFunctions, Icon, Set AI Mode, resources\img\ico\obsbot.ico
Menu OBSBOTFunctions, Add, Set Gimbal Possition, ScriptGenerator_OBSBOT_SetGimbalPossition
Menu OBSBOTFunctions, Icon, Set Gimbal Possition, resources\img\ico\obsbot.ico

Menu Notifications, Add, Telegram, NotImplemented
Menu Notifications, Icon, Telegram, resources\img\ico\telegram.ico
Menu Notifications, Add, Whatsapp, NotImplemented
Menu Notifications, Icon, Whatsapp, resources\img\ico\whatsapp.ico
Menu Notifications, Add, Discord, NotImplemented
Menu Notifications, Icon, Discord, resources\img\ico\discord.ico
Menu Notifications, Add, Microsoft Teams, NotImplemented
Menu Notifications, Icon, Microsoft Teams, resources\img\ico\teams.ico
Menu Notifications, Add, Gmail, NotImplemented
Menu Notifications, Icon, Gmail, resources\img\ico\gmail.ico
Menu Notifications, Add, Twitch, NotImplemented
Menu Notifications, Icon, Twitch, resources\img\ico\twitch.ico

Menu scriptGenerator, Add, Multimedia, :MultimediaFunctions
Menu scriptGenerator, Icon, Multimedia, imageres.dll, 19
Menu scriptGenerator, Add, Web Browser, :WebBrowserCommands
Menu scriptGenerator, Icon, Web Browser, shell32.dll, 221
Menu scriptGenerator, Add, Quick Actions, :QuickActionsMenu
Menu scriptGenerator, Icon, Quick Actions, .\resources\img\ico\windows\pin.ico
Menu scriptGenerator, Add, Hidden Function Keys (F13-F24), :FunctionKeysMenu
Menu scriptGenerator, Icon, Hidden Function Keys (F13-F24), imageres.dll, 174
Menu scriptGenerator, Add, OBS Functions, :OBSFunctions
Menu scriptGenerator, Icon, OBS Functions, resources\img\ico\OBS.ico
Menu scriptGenerator, Add, OBSBOT Functions, :OBSBOTFunctions
Menu scriptGenerator, Icon, OBSBOT Functions, resources\img\ico\OBSBOT.ico
Menu scriptGenerator, Add, Notifications, :Notifications
Menu scriptGenerator, Icon, Notifications, resources\img\ico\telegram.ico

Menu ContextMenu, Add, Edit Script`tShift + Click, GuiEditarScript
Menu ContextMenu, Default, Edit Script`tShift + Click
Menu ContextMenu, Icon, Edit Script`tShift + Click, .\resources\img\ico\windows\edit2.ico
Menu ContextMenu, Add, Script Generator`tAlt + Right Click, :scriptGenerator
Menu ContextMenu, Icon, Script Generator`tAlt + Right Click, shell32.dll, 85
Menu ContextMenu, Add, Change/Del Image`tCtrl + Shift + Click, GuiCambiarImagenBoton
Menu ContextMenu, Icon, Change/Del Image`tCtrl + Shift + Click, shell32.dll, 142
Menu ContextMenu, Add, Button Name`tCtrl + Click, GuiInfoBoton
Menu ContextMenu, Icon, Button Name`tCtrl + Click, shell32.dll, 24
Menu ContextMenu, Add, Create Folder Button, CreateFolderButton
Menu ContextMenu, Icon, Create Folder Button, .\resources\img\ico\windows\folder.ico
Menu ContextMenu, Add, Delete Folder Button, DeleteFolderButton
Menu ContextMenu, Icon, Delete Folder Button, shell32.dll, 235
Menu ContextMenu, Add, Delete Button Function, DeleteButtonFunction
Menu ContextMenu, Icon, Delete Button Function, shell32.dll, 132

; CONNECTION TO SERVER (ONLINE == 1)
if(conf.online)
{
	GuiControl, splashScreen:, splashTxt, % conf.ip ":" conf.port " - Connecting to server..."
	sleep, 1 ; Needed to apply previous GuiControl
	global tcpCon := new SocketTCP()
	tcpCon.connect(conf.ip, conf.port)
	tcpCon.onRecv := Func("OnTcpRecv")
	if(tcpCon.errorNM != "")
	{
		gosub, precargaIconosLocalesEnRam
		GuiControl, , wifi_icon, % btnPics["wifi_icon_offline.png"] ? "HBITMAP:*" btnPics["wifi_icon_offline.png"] : ""
		serverFound := 0 ; Online Mode but couldn't connect, so we keep Offline Functionality
		GuiControl, splashScreen:, splashTxt, % tcpCon.errorNM
		Sleep, 500
	}
	else
	{
		serverFound := 1
		GuiControl, splashScreen:, splashTxt, % "Connected! Downloading Profile..."
		gosub, downloadServerProfile
		GuiControl, , wifi_icon, % btnPics["wifi_icon_online.png"] ? "HBITMAP:*" btnPics["wifi_icon_online.png"] : ""
		FileRead, server_config, % "./resources/img/" conf.ip "/resourcePack_info.txt"
		server_config := ParseJson(server_config)
		conf.folderButtons := server_config.folderButtons
	}
}
else
{
	gosub, precargaIconosLocalesEnRam
}

GuiControl, splashScreen:, splashTxt, % "Creating GUI..."
; GUI
; *******************************
Gui, Color, 282828
Gui -Caption +LastFound +ToolWindow +HwndwindowHandler +E0x02080000
; Fila1
Gui Add, Picture, +BackgroundTrans gBoton1 vBoton1, % btnPics["1.png"] ? "HBITMAP:*" btnPics["1.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
Gui Add, Picture, +BackgroundTrans gBoton2 vBoton2, % btnPics["2.png"] ? "HBITMAP:*" btnPics["2.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
Gui Add, Picture, +BackgroundTrans gBoton3 vBoton3, % btnPics["3.png"] ? "HBITMAP:*" btnPics["3.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
Gui Add, Picture, +BackgroundTrans gBoton4 vBoton4, % btnPics["4.png"] ? "HBITMAP:*" btnPics["4.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
Gui Add, Picture, +BackgroundTrans gBoton5 vBoton5, % btnPics["5.png"] ? "HBITMAP:*" btnPics["5.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
; Fila2
Gui Add, Picture, +BackgroundTrans gBoton6 vBoton6, % btnPics["6.png"] ? "HBITMAP:*" btnPics["6.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
Gui Add, Picture, +BackgroundTrans gBoton7 vBoton7, % btnPics["7.png"] ? "HBITMAP:*" btnPics["7.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
Gui Add, Picture, +BackgroundTrans gBoton8 vBoton8, % btnPics["8.png"] ? "HBITMAP:*" btnPics["8.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
Gui Add, Picture, +BackgroundTrans gBoton9 vBoton9, % btnPics["9.png"] ? "HBITMAP:*" btnPics["9.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
Gui Add, Picture, +BackgroundTrans gBoton10 vBoton10, % btnPics["10.png"] ? "HBITMAP:*" btnPics["10.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
; Fila3
Gui Add, Picture, +BackgroundTrans gBoton11 vBoton11, % btnPics["11.png"] ? "HBITMAP:*" btnPics["11.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
Gui Add, Picture, +BackgroundTrans gBoton12 vBoton12, % btnPics["12.png"] ? "HBITMAP:*" btnPics["12.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
Gui Add, Picture, +BackgroundTrans gBoton13 vBoton13, % btnPics["13.png"] ? "HBITMAP:*" btnPics["13.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
Gui Add, Picture, +BackgroundTrans gBoton14 vBoton14, % btnPics["14.png"] ? "HBITMAP:*" btnPics["14.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
Gui Add, Picture, +BackgroundTrans gBoton15 vBoton15, % btnPics["15.png"] ? "HBITMAP:*" btnPics["15.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
; Fondos Activaciones Botones
Gui Add, Picture, vActivar1 Hidden x120 y40 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar2 Hidden x280 y40 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar3 Hidden x440 y40 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar4 Hidden x600 y40 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar5 Hidden x760 y40 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar6 Hidden x120 y220 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar7 Hidden x280 y220 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar8 Hidden x440 y220 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar9 Hidden x600 y220 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar10 Hidden x760 y220 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar11 Hidden x120 y400 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar12 Hidden x280 y400 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar13 Hidden x440 y400 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar14 Hidden x600 y400 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
Gui Add, Picture, vActivar15 Hidden x760 y400 w150 h150, % btnPics["FondoActivacion.png"] ? "HBITMAP:*" btnPics["FondoActivacion.png"] : ""
; Botones Página
Gui Add, Picture, +BackgroundTrans gRightPage vRightPage x910 y240 w130 h130, % btnPics["RightPage.png"] ? "HBITMAP:*" btnPics["RightPage.png"] : ""
Gui Add, Picture, +BackgroundTrans gLeftPage vLeftPage x0 y240 w130 h130, % btnPics["LeftPage.png"] ? "HBITMAP:*" btnPics["LeftPage.png"] : ""
; Icono Ajustes
Gui Add, Picture, +BackgroundTrans gGuiContextMenu vsettings_icon x960 y0 w64 h64, % btnPics["settings_icon.png"] ? "HBITMAP:*" btnPics["settings_icon.png"] : ""
; Icono Wi-Fi
Gui Add, Picture, +BackgroundTrans gcrearGuiNetworkSettings vwifi_icon x960 y536 w64 h64, % btnPics["wifi_icon_disabled.png"] ? "HBITMAP:*" btnPics["wifi_icon_disabled.png"] : ""
if(serverFound)
{
	GuiControl, , wifi_icon, % btnPics["wifi_icon_online.png"] ? "HBITMAP:*" btnPics["wifi_icon_online.png"] : ""
}
else if(conf.online)
{
	GuiControl, , wifi_icon, % btnPics["wifi_icon_offline.png"] ? "HBITMAP:*" btnPics["wifi_icon_offline.png"] : ""
}
; Fondo y secciones mover
Gui Add, Picture, x0 y0 w1024 h600, % btnPics["background.png"] ? "HBITMAP:*" btnPics["background.png"] : ""
Gui, Add, Text, x0 y0 w1024 h50 cWhite Center GMoverVentana vMoverVentanaUp, ; Mover Ventana de arriba
Gui, Add, Text, x0 y570 w1024 h50 cWhite Center GMoverVentana vMoverVentanaDown, ; Mover Ventana de abajo
EstablecerPagina(0)
Gui, SplashScreen:Destroy
Gui Show, % "w1024 h600 x" conf.x_Inicial "y" conf.y_Inicial, Nova Macros Client
if(conf.miniClient)
{
	conf.miniClient := 0
	gosub, CambiarDimensionesCliente
}
gosub, SetSiempreVisibleInicial
OnMessage(0x404, "AHK_ICONCLICKNOTIFY") ; Detectar doble left click en el icono de notificación para mostrar
gosub, setReactiveService
if(conf.lookForUpdates){
	lookForUpdates(true)
}
Return

; LABELS BOTONES Y FUNCIONES GENERALES
; *******************************
ToggleHide:
if EsVisible
{
	WinHide, Nova Macros Client
	Menu, tray, Rename, Hide, Show
	EsVisible = 0
}
else
{
	WinShow, Nova Macros Client
	WinActivate, Nova Macros Client
	Menu, tray, Rename, Show, Hide
	EsVisible = 1
}
Return

GuiContextMenu:
	if GetKeyState("Alt")
		scriptGen := 1
	else
		scriptGen := 0
	if A_GuiControl In Boton1,Boton2,Boton3,Boton4,Boton5,Boton6,Boton7,Boton8,Boton9,Boton10,Boton11,Boton12,Boton13,Boton14,Boton15
	{
		StringReplace, BotonAPulsar, A_GuiControl, boton,
		if(EnCarpeta){
			BotonActivo := CarpetaBoton 15*PaginaCarpeta+BotonAPulsar
			if(BotonAPulsar == 15)
				return ; Button 15* inside a folder is always a return key (no script attached)
		}
		else
			BotonActivo := 15*NumeroPagina+BotonAPulsar
		if (scriptGen)
		{
			KeyWait, Alt,
			Menu scriptGenerator, Show
		}
		else
		{
			Menu ContextMenu, Show
		}
	}
	else if(A_GuiControl == "settings_icon")
	{
		Menu ContextMenuGenerico, Show
	}
	; Antes el fondo permitía mostrar el botón de acciones, ahora hay un bottón arriba a la derecha para esto (más fácil para el modo táctil y más visual para el usuario nuevo)
	;~ else
		;~ Menu ContextMenuGenerico, Show
return

GuiEditarScript:
	EditarScriptBoton(BotonActivo)
return

GuiCambiarImagenBoton:
	EstablecerImagenBoton(BotonActivo)
return

GuiInfoBoton:
	MsgBox,,Button ID, Clicked button Id is: %BotonActivo%
return

ScriptGenerator_RunFile:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\RunFile.ahk" %BotonActivo%
return

ScriptGenerator_RunCmd:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\RunCmd.ahk" %BotonActivo%
return

ScriptGenerator_SendText:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\SendTextBlock.ahk" %BotonActivo%
return

ScriptGenerator_Hotkey:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\HotkeyCreator.ahk" %BotonActivo%
return

ScriptGenerator_Multimedia_PlayPause:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_Multimedia_PlayPause.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_Multimedia_Stop:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_Multimedia_Stop.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_Multimedia_Next:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_Multimedia_Next.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_Multimedia_Previous:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_Multimedia_Previous.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_Multimedia_MoreVolume:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_Multimedia_MoreVolume.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_Multimedia_LessVolume:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_Multimedia_LessVolume.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_Multimedia_Mute:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_Multimedia_Mute.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_FunctionKeys_F13:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_FunctionKeys_F13.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_FunctionKeys_F14:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_FunctionKeys_F14.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_FunctionKeys_F15:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_FunctionKeys_F15.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_FunctionKeys_F16:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_FunctionKeys_F16.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_FunctionKeys_F17:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_FunctionKeys_F17.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_FunctionKeys_F18:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_FunctionKeys_F18.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_FunctionKeys_F19:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_FunctionKeys_F19.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_FunctionKeys_F20:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_FunctionKeys_F20.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_FunctionKeys_F21:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_FunctionKeys_F21.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_FunctionKeys_F22:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_FunctionKeys_F22.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_FunctionKeys_F23:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_FunctionKeys_F23.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_FunctionKeys_F24:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_FunctionKeys_F24.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_WebBrowser_NextTab:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_WebBrowser_NextTab.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_WebBrowser_PreviousTab:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_WebBrowser_PreviousTab.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_WebBrowser_NewTab:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_WebBrowser_NewTab.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_WebBrowser_NewWindow:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_WebBrowser_NewWindow.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_WebBrowser_CloseTab:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_WebBrowser_CloseTab.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_WebBrowser_RestoreTab:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_WebBrowser_RestoreTab.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_WebBrowser_ChromePrivWindow:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_WebBrowser_ChromePrivWindow.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_CloseWindow:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_CloseWindow.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_Maximize:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_Maximize.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_Minimize:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_Minimize.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_ShowDesktop:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_ShowDesktop.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_NewExplorer:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_NewExplorer.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_NewFolder:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_NewFolder.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_QuickRename:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_QuickRename.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_LockPC:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_LockPC.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_Shutdown:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_Shutdown.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_SystemInfo:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_SystemInfo.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_FullSystemInfo:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_FullSystemInfo.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_Cmd:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_Cmd.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_PowerShell:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_PowerShell.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_ScreenShot:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_ScreenShot.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_SnipImage:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_SnipImage.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_GamePanel:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_GamePanel.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_QuickActions_EmojiPanel:
	if(ComprobarExistenciaBoton())
		FileCopy, lib\script_generator\code_snippets\ScriptGenerator_QuickActions_EmojiPanel.ahk,%BotonActivo%.ahk,1
return

ScriptGenerator_OBS_HideShowSource:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBS_HideShowSource.ahk" %BotonActivo%
return

ScriptGenerator_OBS_SetScene:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBS_SetScene.ahk" %BotonActivo%
return

ScriptGenerator_OBS_Record:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBS_Record.ahk" %BotonActivo%
return

ScriptGenerator_OBS_StopRecord:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBS_StopRecord.ahk" %BotonActivo%
return

ScriptGenerator_OBS_PauseRecord:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBS_PauseRecord.ahk" %BotonActivo%
return

ScriptGenerator_OBS_ResumeRecord:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBS_ResumeRecord.ahk" %BotonActivo%
return

ScriptGenerator_OBS_MuteUnmuteSource:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBS_MuteUnmuteSource.ahk" %BotonActivo%
return

ScriptGenerator_OBS_ShowCurrentScene:
	if(ComprobarExistenciaBoton())
		FileCopy, % A_ScriptDir "\lib\script_generator\OBS_ShowCurrentScene.ahk", % A_ScriptDir "\" BotonActivo ".ahk", 1
return

ScriptGenerator_OBS_SoundPannel:
	if(ComprobarExistenciaBoton()){
		FileDelete, % "" BotonActivo ".ahk"
		scriptContent :=
		(LTrim
		"#NoEnv
		#SingleInstance, Force
		#NoTrayIcon
		SetWorkingDir " A_ScriptDir "\plugins\obs_sound_control
		Run, " A_ScriptDir "\plugins\obs_sound_control\obs_sound_panel.ahk"
		)
		FileAppend, % scriptContent, % "" BotonActivo ".ahk"
	}
return

ScriptGenerator_OBSBOT_Sleep:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBSBOT_Sleep.ahk" %BotonActivo%
return

ScriptGenerator_OBSBOT_Wake:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBSBOT_Wake.ahk" %BotonActivo%
return

ScriptGenerator_OBSBOT_SetZoom:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBSBOT_SetZoom.ahk" %BotonActivo%
return

ScriptGenerator_OBSBOT_StartRecording:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBSBOT_StartRecording.ahk" %BotonActivo%
return

ScriptGenerator_OBSBOT_StopRecording:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBSBOT_StopRecording.ahk" %BotonActivo%
return

ScriptGenerator_OBSBOT_TakePhoto:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBSBOT_TakePhoto.ahk" %BotonActivo%
return

ScriptGenerator_OBSBOT_ResetGimbal:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBSBOT_ResetGimbal.ahk" %BotonActivo%
return

ScriptGenerator_OBSBOT_SetFOV:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBSBOT_SetFOV.ahk" %BotonActivo%
return

ScriptGenerator_OBSBOT_Mirror:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBSBOT_Mirror.ahk" %BotonActivo%
return

ScriptGenerator_OBSBOT_TrackingMode:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBSBOT_TrackingMode.ahk" %BotonActivo%
return

ScriptGenerator_OBSBOT_AILock:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBSBOT_AILock.ahk" %BotonActivo%
return

ScriptGenerator_OBSBOT_AIMode:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBSBOT_AIMode.ahk" %BotonActivo%
return

ScriptGenerator_OBSBOT_SetGimbalPossition:
	Run, %A_ScriptDir%\lib\autohotkey.exe "lib\script_generator\OBSBOT_SetGimbalPossition.ahk" %BotonActivo%
return

NotImplemented:
	MsgBox, Not implemented
return

ComprobarExistenciaBoton()
{
	buttonPath := "" BotonActivo ".ahk"
	if FileExist(buttonPath)
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBoxBtn1 = Overwrite
		MsgBoxBtn2 = Cancel
		MsgBox 0x34, Overwrite?, This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			return 1
		}else{
			return 0
		}
	}
	else
	{
		return 1
	}
}

SiempreVisible:
	if(conf.siempreVisible)
	{
		Winset, AlwaysOnTop, Off, Nova Macros Client
		conf.siempreVisible := 0
		Menu ContextMenuGenerico, UnCheck, Always on Top
	}
	else
	{
		Winset, AlwaysOnTop, , Nova Macros Client
		conf.siempreVisible := 1
		Menu ContextMenuGenerico, Check, Always on Top
	}
	gosub, guardarConfig
return

SetSiempreVisibleInicial:
	if(!conf.siempreVisible)
	{
		Winset, AlwaysOnTop, Off, Nova Macros Client
		Menu ContextMenuGenerico, UnCheck, Always on Top
	}
	else
	{
		Winset, AlwaysOnTop, , Nova Macros Client
		Menu ContextMenuGenerico, Check, Always on Top
	}
return

MoverRatonAlPulsarBotonToggle:
	if(conf.moverRatonAlPulsarBoton)
	{
		conf.moverRatonAlPulsarBoton := 0
		Menu ContextMenuGenerico, UnCheck, Center Mouse after Activation
	}
	else
	{
		conf.moverRatonAlPulsarBoton := 1
		Menu ContextMenuGenerico, Check, Center Mouse after Activation
	}
	gosub, guardarConfig
return

enviarAltTabAlPulsarBotonToggle:
	if(conf.enviarAltTabAlPulsarBoton)
	{
		conf.enviarAltTabAlPulsarBoton := 0
		Menu ContextMenuGenerico, UnCheck, Send Alt+Tab after Activation
	}
	else
	{
		conf.enviarAltTabAlPulsarBoton := 1
		Menu ContextMenuGenerico, Check, Send Alt+Tab after Activation
	}
	gosub, guardarConfig
return

cargaProgresivaIconosToggle:
	if(conf.cargaProgresivaIconos)
	{
		conf.cargaProgresivaIconos := 0
		Menu ContextMenuGenerico, UnCheck, Progressive Icon Loading
	}
	else
	{
		conf.cargaProgresivaIconos := 1
		Menu ContextMenuGenerico, Check, Progressive Icon Loading
	}
	gosub, guardarConfig
return

toggleBuiltInAhk:
	if(conf.builtin_ahk)
	{
		conf.builtin_ahk := 0
		Menu ContextMenuGenerico, UnCheck, Use built-in AHK
	}
	else
	{
		conf.builtin_ahk := 1
		Menu ContextMenuGenerico, Check, Use built-in AHK
	}
	gosub, guardarConfig
return
 
CambiarDimensionesCliente:
if(!conf.cargaProgresivaIconos)
	DllCall("LockWindowUpdate", "UInt", windowHandler)
if conf.miniClient
{
	Menu, ContextMenuGenerico, Rename, Normal Client, Mini Client
	conf.miniClient := 0
	GuiControl, MoveDraw, Activar1, x120 y40 w150 h150
	GuiControl, MoveDraw, Activar2, x280 y40 w150 h150
	GuiControl, MoveDraw, Activar3, x440 y40 w150 h150
	GuiControl, MoveDraw, Activar4, x600 y40 w150 h150
	GuiControl, MoveDraw, Activar5, x760 y40 w150 h150
	GuiControl, MoveDraw, Activar6, x120 y220 w150 h150
	GuiControl, MoveDraw, Activar7, x280 y220 w150 h150
	GuiControl, MoveDraw, Activar8, x440 y220 w150 h150
	GuiControl, MoveDraw, Activar9, x600 y220 w150 h150
	GuiControl, MoveDraw, Activar10, x760 y220 w150 h150
	GuiControl, MoveDraw, Activar11, x120 y400 w150 h150
	GuiControl, MoveDraw, Activar12, x280 y400 w150 h150
	GuiControl, MoveDraw, Activar13, x440 y400 w150 h150
	GuiControl, MoveDraw, Activar14, x600 y400 w150 h150
	GuiControl, MoveDraw, Activar15, x760 y400 w150 h150
	GuiControl, MoveDraw, LeftPage, x0 y230 w130 h130
	GuiControl, MoveDraw, RightPage, x910 y230 w130 h130
	GuiControl, MoveDraw, MoverVentanaUp, x0 y0 w1024 h50
	GuiControl, MoveDraw, MoverVentanaDown, x0 y570 w1024 h50
	GuiControl, MoveDraw, wifi_icon, x960 y536 w64 h64
	GuiControl, MoveDraw, settings_icon, x960 y0 w64 h64
	Gui Show, w1024 h600, Nova Macros Client
}
else
{
	Menu, ContextMenuGenerico, Rename, Mini Client, Normal Client
	conf.miniClient := 1
	GuiControl, MoveDraw, Activar1, x54 y14 w59 h59
	GuiControl, MoveDraw, Activar2, x110 y14 w59 h59
	GuiControl, MoveDraw, Activar3, x166 y14 w59 h59
	GuiControl, MoveDraw, Activar4, x222 y14 w59 h59
	GuiControl, MoveDraw, Activar5, x278 y14 w59 h59
	GuiControl, MoveDraw, Activar6, x54 y70 w59 h59
	GuiControl, MoveDraw, Activar7, x110 y70 w59 h59
	GuiControl, MoveDraw, Activar8, x166 y70 w59 h59
	GuiControl, MoveDraw, Activar9, x222 y70 w59 h59
	GuiControl, MoveDraw, Activar10, x278 y70 w59 h59
	GuiControl, MoveDraw, Activar11, x54 y126 w59 h59
	GuiControl, MoveDraw, Activar12, x110 y126 w59 h59
	GuiControl, MoveDraw, Activar13, x166 y126 w59 h59
	GuiControl, MoveDraw, Activar14, x222 y126 w59 h59
	GuiControl, MoveDraw, Activar15, x278 y126 w59 h59
	GuiControl, MoveDraw, LeftPage, x0 y75 w49 h49
	GuiControl, MoveDraw, RightPage, x340 y75 w49 h49
	GuiControl, MoveDraw, MoverVentanaUp, x-8 y0 w413 h23
	GuiControl, MoveDraw, MoverVentanaDown, x0 y187 w401 h23
	GuiControl, MoveDraw, wifi_icon, x353 y168 w32 h32
	GuiControl, MoveDraw, settings_icon, x353 y0 w32 h32
	Gui, Show, w385 h200, Nova Macros Client
}
gosub, setWifiIcon ; Resets the wifi icon without loosing quality bug on resize
DllCall("LockWindowUpdate", "UInt", 0)
gosub, guardarConfig
; Refrescar Botones para no perder calidad de imagen por bug resize
if(conf.miniClient)
{
	RefrescarBotonesMini()
}
else
{
	RefrescarBotones()
}
if(EnCarpeta)
{
	EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
}
else
{
	EstaBlecerPagina(NumeroPagina)
}
Return

MoverVentana:
PostMessage, 0xA1, 2,,, A 
Return

Boton1:
PulsarBoton(1)
return

Boton2:
PulsarBoton(2)
return

Boton3:
PulsarBoton(3)
return

Boton4:
PulsarBoton(4)
return

Boton5:
PulsarBoton(5)
return

Boton6:
PulsarBoton(6)
return

Boton7:
PulsarBoton(7)
return

Boton8:
PulsarBoton(8)
return

Boton9:
PulsarBoton(9)
return

Boton10:
PulsarBoton(10)
return

Boton11:
PulsarBoton(11)
return

Boton12:
PulsarBoton(12)
return

Boton13:
PulsarBoton(13)
return

Boton14:
PulsarBoton(14)
return

Boton15:
PulsarBoton(15)
return

PulsarBoton(BotonAPulsar)
{
	if(conf.moverRatonAlPulsarBoton)
		MouseMove, % conf.pantalla_Mitad_X, % conf.pantalla_Mitad_Y, 0
	if(conf.reactiveWindow){
		SetTimer, setPageByActiveProgram, 1000
	}
	AltTab()
	; Lógica Botón
	if(EnCarpeta)
	{
		if(BotonAPulsar != 15)
		{
			IdBoton := CarpetaBoton 15*PaginaCarpeta+BotonAPulsar
			if GetKeyState("Control")
			{
				if GetKeyState("Shift")
				{
					EstablecerImagenBoton(IdBoton)
					return
				}
				MsgBox,,Button ID, Clicked button Id is: %IdBoton%
				return
			}
			if GetKeyState("Shift")
			{
				EditarScriptBoton(IdBoton)
				return
			}
			if(conf.online && serverFound)
			{
				if(conf.folderButtons[idBoton] != "")
				{
					CarpetaBoton := conf.folderButtons[idBoton]
					global PaginaCarpeta := 0
					EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
					return
				}
			}
			else
			{
				if(conf.folderButtons[idBoton] != "")
				{
					CarpetaBoton := conf.folderButtons[idBoton]
					global PaginaCarpeta := 0
					EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
					return
				}
			}
			EjecutarFuncionBoton(BotonAPulsar, IdBoton)
		}
		else if (BotonAPulsar = 15)
		{
			; Este es un caso especial ya que si está en carpeta siempre tiene el valor volver (salir fuera de la carpeta)
			IdBoton := CarpetaBoton 15*PaginaCarpeta+BotonAPulsar
			EstablecerPagina(NumeroPagina)
			EnCarpeta = 0
			Menu ContextMenuGenerico, Disable, Bind this folder to a program or window
			PaginaCarpeta = 0
			return	
		}
	}
	else
	{
		IdBoton := 15*NumeroPagina+BotonAPulsar
		if GetKeyState("Control")
		{
			if GetKeyState("Shift")
			{
				EstablecerImagenBoton(IdBoton)
				return
			}
			MsgBox,,Button ID, Clicked button Id is: %IdBoton%
			return
		}
		if GetKeyState("Shift")
		{
			EditarScriptBoton(IdBoton)
			return
		}
		if(conf.online && serverFound)
		{
			if(conf.folderButtons[idBoton] != "")
			{
				CarpetaBoton := conf.folderButtons[idBoton]
				global PaginaCarpeta := 0
				EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
				return
			}
		}
		else
		{
			if(conf.folderButtons[idBoton] != "")
			{
				CarpetaBoton := conf.folderButtons[idBoton]
				global PaginaCarpeta := 0
				EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
				return
			}
		}
		EjecutarFuncionBoton(BotonAPulsar, IdBoton)
	}
	Boton%BotonAPulsar% = 1
}

EstablecerPagina(NumeroPagina)
{
	global
	if(!conf.cargaProgresivaIconos)
		DllCall("LockWindowUpdate", "UInt", windowHandler)
	CarpetaBoton := ""
	RutaBoton1 := CarpetaBoton 15*NumeroPagina+1 ".png"
	RutaBoton2 := CarpetaBoton 15*NumeroPagina+2 ".png"
	RutaBoton3 := CarpetaBoton 15*NumeroPagina+3 ".png"
	RutaBoton4 := CarpetaBoton 15*NumeroPagina+4 ".png"
	RutaBoton5 := CarpetaBoton 15*NumeroPagina+5 ".png"
	RutaBoton6 := CarpetaBoton 15*NumeroPagina+6 ".png"
	RutaBoton7 := CarpetaBoton 15*NumeroPagina+7 ".png"
	RutaBoton8 := CarpetaBoton 15*NumeroPagina+8 ".png"
	RutaBoton9 := CarpetaBoton 15*NumeroPagina+9 ".png"
	RutaBoton10 := CarpetaBoton 15*NumeroPagina+10 ".png"
	RutaBoton11 := CarpetaBoton 15*NumeroPagina+11 ".png"
	RutaBoton12 := CarpetaBoton 15*NumeroPagina+12 ".png"
	RutaBoton13 := CarpetaBoton 15*NumeroPagina+13 ".png"
	RutaBoton14 := CarpetaBoton 15*NumeroPagina+14 ".png"
	RutaBoton15 := CarpetaBoton 15*NumeroPagina+15 ".png"
	
	if(conf.miniClient)
	{
		RefrescarBotonesMini()
	}
	else
	{
		RefrescarBotones()
	}
	DllCall("LockWindowUpdate", "UInt", 0)
}

EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
{
	global
	EnCarpeta = 1
	Menu ContextMenuGenerico, Enable, Bind this folder to a program or window
	if(!conf.cargaProgresivaIconos)
		DllCall("LockWindowUpdate", "UInt", windowHandler)
	RutaBoton1 := CarpetaBoton 15*PaginaCarpeta+1 ".png"
	RutaBoton2 := CarpetaBoton 15*PaginaCarpeta+2 ".png"
	RutaBoton3 := CarpetaBoton 15*PaginaCarpeta+3 ".png"
	RutaBoton4 := CarpetaBoton 15*PaginaCarpeta+4 ".png"
	RutaBoton5 := CarpetaBoton 15*PaginaCarpeta+5 ".png"
	RutaBoton6 := CarpetaBoton 15*PaginaCarpeta+6 ".png"
	RutaBoton7 := CarpetaBoton 15*PaginaCarpeta+7 ".png"
	RutaBoton8 := CarpetaBoton 15*PaginaCarpeta+8 ".png"
	RutaBoton9 := CarpetaBoton 15*PaginaCarpeta+9 ".png"
	RutaBoton10 := CarpetaBoton 15*PaginaCarpeta+10 ".png"
	RutaBoton11 := CarpetaBoton 15*PaginaCarpeta+11 ".png"
	RutaBoton12 := CarpetaBoton 15*PaginaCarpeta+12 ".png"
	RutaBoton13 := CarpetaBoton 15*PaginaCarpeta+13 ".png"
	RutaBoton14 := CarpetaBoton 15*PaginaCarpeta+14 ".png"
		
	if(conf.miniClient)
	{
		RefrescarBotonesMini(true)
	}
	else
	{
		RefrescarBotones(true)
	}
	DllCall("LockWindowUpdate", "UInt", 0)
}

RefrescarBotones(esCarpeta = false)
{
	global
	if(!conf.cargaProgresivaIconos)
		DllCall("LockWindowUpdate", "UInt", windowHandler)
	GuiControl, Text, Boton1, % btnPics[RutaBoton1] ? "HBITMAP:*" btnPics[RutaBoton1] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton1, x130 y50 w130 h130 ; Al cambiarle la ruta hay que resizear el boton
	GuiControl, Text, Boton2, % btnPics[RutaBoton2] ? "HBITMAP:*" btnPics[RutaBoton2] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton2, x290 y50 w130 h130
	GuiControl, Text, Boton3, % btnPics[RutaBoton3] ? "HBITMAP:*" btnPics[RutaBoton3] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton3, x450 y50 w130 h130
	GuiControl, Text, Boton4, % btnPics[RutaBoton4] ? "HBITMAP:*" btnPics[RutaBoton4] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton4, x610 y50 w130 h130
	GuiControl, Text, Boton5, % btnPics[RutaBoton5] ? "HBITMAP:*" btnPics[RutaBoton5] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton5, x770 y50 w130 h130
	GuiControl, Text, Boton6, % btnPics[RutaBoton6] ? "HBITMAP:*" btnPics[RutaBoton6] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton6, x130 w130 y230 h130
	GuiControl, Text, Boton7, % btnPics[RutaBoton7] ? "HBITMAP:*" btnPics[RutaBoton7] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton7, x290 w130 y230 h130
	GuiControl, Text, Boton8, % btnPics[RutaBoton8] ? "HBITMAP:*" btnPics[RutaBoton8] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton8, x450 w130 y230 h130
	GuiControl, Text, Boton9, % btnPics[RutaBoton9] ? "HBITMAP:*" btnPics[RutaBoton9] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton9, x610 w130 y230 h130
	GuiControl, Text, Boton10, % btnPics[RutaBoton10] ? "HBITMAP:*" btnPics[RutaBoton10] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton10, x770 y230 w130 h130
	GuiControl, Text, Boton11, % btnPics[RutaBoton11] ? "HBITMAP:*" btnPics[RutaBoton11] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton11, x130 x130 y410 w130 h130
	GuiControl, Text, Boton12, % btnPics[RutaBoton12] ? "HBITMAP:*" btnPics[RutaBoton12] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton12, x290 y410 w130 h130
	GuiControl, Text, Boton13, % btnPics[RutaBoton13] ? "HBITMAP:*" btnPics[RutaBoton13] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton13, x450 y410 w130 h130
	GuiControl, Text, Boton14, % btnPics[RutaBoton14] ? "HBITMAP:*" btnPics[RutaBoton14] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton14, x610 y410 w130 h130
	if(esCarpeta)
	{
		GuiControl, Text, Boton15,  % btnPics["Volver.png"] ? "HBITMAP:*" btnPics["Volver.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
		GuiControl, MoveDraw, Boton15, x770 y410 w130 h130	
	}
	else
	{
		GuiControl, Text, Boton15,  % btnPics[RutaBoton15] ? "HBITMAP:*" btnPics[RutaBoton15] : "HBITMAP:*" btnPics["button_placeholder.png"]
		GuiControl, MoveDraw, Boton15, x770 y410 w130 h130		
	}
	DllCall("LockWindowUpdate", "UInt", 0)
}

RefrescarBotonesMini(esCarpeta = false)
{
	global
	if(!conf.cargaProgresivaIconos)
		DllCall("LockWindowUpdate", "UInt", windowHandler)
	GuiControl, Text, Boton1, % btnPics[RutaBoton1] ? "HBITMAP:*" btnPics[RutaBoton1] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton1, x59 y19 w49 h49
	GuiControl, Text, Boton2, % btnPics[RutaBoton2] ? "HBITMAP:*" btnPics[RutaBoton2] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton2, x115 y19 w49 h49
	GuiControl, Text, Boton3, % btnPics[RutaBoton3] ? "HBITMAP:*" btnPics[RutaBoton3] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton3, x171 y19 w49 h49
	GuiControl, Text, Boton4, % btnPics[RutaBoton4] ? "HBITMAP:*" btnPics[RutaBoton4] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton4, x227 y19 w49 h49
	GuiControl, Text, Boton5, % btnPics[RutaBoton5] ? "HBITMAP:*" btnPics[RutaBoton5] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton5, x283 y19 w49 h49
	GuiControl, Text, Boton6, % btnPics[RutaBoton6] ? "HBITMAP:*" btnPics[RutaBoton6] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton6, x59 y75 w49 h49
	GuiControl, Text, Boton7, % btnPics[RutaBoton7] ? "HBITMAP:*" btnPics[RutaBoton7] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton7, x115 y75 w49 h49
	GuiControl, Text, Boton8, % btnPics[RutaBoton8] ? "HBITMAP:*" btnPics[RutaBoton8] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton8, x171 y75 w49 h49
	GuiControl, Text, Boton9, % btnPics[RutaBoton9] ? "HBITMAP:*" btnPics[RutaBoton9] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton9, x227 y75 w49 h49
	GuiControl, Text, Boton10, % btnPics[RutaBoton10] ? "HBITMAP:*" btnPics[RutaBoton10] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton10, x283 y75 w49 h49
	GuiControl, Text, Boton11, % btnPics[RutaBoton11] ? "HBITMAP:*" btnPics[RutaBoton11] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton11, x59 y131 w49 h49
	GuiControl, Text, Boton12, % btnPics[RutaBoton12] ? "HBITMAP:*" btnPics[RutaBoton12] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton12, x115 y131 w49 h49
	GuiControl, Text, Boton13, % btnPics[RutaBoton13] ? "HBITMAP:*" btnPics[RutaBoton13] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton13, x171 y131 w49 h49
	GuiControl, Text, Boton14, % btnPics[RutaBoton14] ? "HBITMAP:*" btnPics[RutaBoton14] : "HBITMAP:*" btnPics["button_placeholder.png"]
	GuiControl, MoveDraw, Boton14, x227 y131 w49 h49
	if(esCarpeta)
	{
		GuiControl, Text, Boton15, % btnPics["Volver.png"] ? "HBITMAP:*" btnPics["Volver.png"] : "HBITMAP:*" btnPics["button_placeholder.png"]
		GuiControl, MoveDraw, Boton15, x283 y131 w49 h49
	}
	else
	{
		GuiControl, Text, Boton15, % btnPics[RutaBoton15] ? "HBITMAP:*" btnPics[RutaBoton15] : "HBITMAP:*" btnPics["button_placeholder.png"]
		GuiControl, MoveDraw, Boton15, x283 y131 w49 h49
	}
	DllCall("LockWindowUpdate", "UInt", 0)
}

LeftPage:
	if(conf.moverRatonAlPulsarBoton)
		MouseMove, % conf.pantalla_Mitad_X, % conf.pantalla_Mitad_Y, 0
	AltTab()
	if(EnCarpeta)
	{
		if(PaginaCarpeta != 0)
		{
			if GetKeyState("Control")
			{
				if(PaginaCarpeta >= 10)
				{
					PaginaCarpeta := PaginaCarpeta - 10
					EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
				}
				return
			}
			PaginaCarpeta--
			EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
		}
	}
	else
	{
		if(NumeroPagina != 0)
		{
			if GetKeyState("Control")
			{
				if(NumeroPagina >= 10)
				{
					NumeroPagina := NumeroPagina - 10
					EstablecerPagina(NumeroPagina)
				}
			}
			else
			{
				NumeroPagina--
				EstablecerPagina(NumeroPagina)
			}
		}
	}
return

RightPage:
	if(conf.moverRatonAlPulsarBoton)
		MouseMove, % conf.pantalla_Mitad_X, % conf.pantalla_Mitad_Y, 0
	AltTab()
	if(EnCarpeta)
	{
		if GetKeyState("Control")
		{
			PaginaCarpeta := PaginaCarpeta + 10
			EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
			return
		}
		PaginaCarpeta++
		EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
	}
	else
	{
		if GetKeyState("Control")
		{
			NumeroPagina := NumeroPagina + 10
		}
		else
		{
			NumeroPagina++
		}
		EstablecerPagina(NumeroPagina)
	}
return

EstablecerImagenBoton(IdBoton)
{
	global btnPics
	OnMessage(0x44, "OnMsgBox")
	MsgBoxBtn1 = Change Img
	MsgBoxBtn2 = Remove
	MsgBoxBtn3 = Cancel
	MsgBox 0x23, Change - Delete, Change Image or Remove Button?
	OnMessage(0x44, "")

	IfMsgBox Yes, {
		FileSelectFile, ImagenAEstablecer, ,,,*.jpg; *.png; *.gif; *.jpeg; *.bmp; *.ico
		if ImagenAEstablecer =
			MsgBox, No image selected!
		else
		{
			FileCopy, %ImagenAEstablecer%, ./resources/img/%IdBoton%.png, 1
			DllCall("DeleteObject", "ptr", btnPics[IdBoton ".png"]) ; Dispose image from memory
			btnPics[IdBoton ".png"] := LoadPicture("./resources/img/" IdBoton ".png")
		}
	} 
	Else IfMsgBox No, {
		FileDelete,./resources/img/%IdBoton%.png
		DllCall("DeleteObject", "ptr", btnPics[IdBoton ".png"]) ; Dispose image from memory
		btnPics[IdBoton ".png"] := ""
		if(FileExist("./" IdBoton ".ahk"))
		{
			OnMessage(0x44, "OnMsgBox")
			MsgBoxBtn1 = Delete
			MsgBoxBtn2 = Keep
			MsgBox 0x34, Overwrite?, This button has a macro file`, do you want to delete it?`n`nIts function will be lost!
			OnMessage(0x44, "")

			IfMsgBox Yes, {
				FileDelete, %IdBoton%.ahk
			}
		}
	} 
	Else IfMsgBox Cancel, {
		return
	}	
	;~ Sleep, 300 ; Lo he quitado porque para qué esperar
	if(EnCarpeta)
	{
		EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
	}
	else
	{
		EstablecerPagina(NumeroPagina)	
	}
}

EditarScriptBoton(IdBoton)
{
	RutaScript := "" IdBoton "." conf.extension ""
	if(!FileExist(RutaScript))
	{
		FileAppend,,%RutaScript%
	}
	Run, % conf.scriptEditorPath " " RutaScript
}

CambiarRutaEditor:
	; Ruta Editor
	FileSelectFile, RutaEditorScripts, ,,,*.exe
	if RutaEditorScripts =
		MsgBox, No executable selected!
	else
	{
		StringReplace, RutaEditorScripts, RutaEditorScripts, \, \\, All
		conf.scriptEditorPath := RutaEditorScripts
	}
	; Extension Scripts
	InputBox, ExtensionScripts, Button Script EXT, Insert the extension of the Scripts triggered by the buttons`nExamples`: exe`, ahk`, py`.`.`., , 500, 145,,,,,ahk
	if ExtensionScripts =
		MsgBox, Couldn't retrieve the extension!
	else
	{
		conf.extension := ExtensionScripts
	}
	gosub, guardarConfig
return

GuiClose:
Exit:
	ExitApp

; HOTKEYS
; *******************************
~Right::
	SetTitleMatchMode, 3
	IfWinActive, Nova Macros Client ahk_class AutoHotkeyGUI
	{
		gosub, RightPage
	}
	SetTitleMatchMode, 1
return

~Left::
	SetTitleMatchMode, 3
	IfWinActive, Nova Macros Client ahk_class AutoHotkeyGUI
	{
		gosub, LeftPage
	}
	SetTitleMatchMode, 1
return

~^Right::
	SetTitleMatchMode, 3
	IfWinActive, Nova Macros Client ahk_class AutoHotkeyGUI
	{
		gosub, RightPage ; Incremento de 10 en 10
	}
	SetTitleMatchMode, 1
return

~^Left::
	SetTitleMatchMode, 3
	IfWinActive, Nova Macros Client ahk_class AutoHotkeyGUI
	{
		gosub, LeftPage ; Decremento de 10 en 10
	}
	SetTitleMatchMode, 1
return

EjecutarFuncionBoton(BotonVisual, FicheroEjecutar)
{
	if(conf.online && serverFound)
	{
		EnviarTCP("{""BotonVisual"":""" BotonVisual """,""FicheroEjecutar"":""" FicheroEjecutar "." conf.extension """}")
		;~ OutputDebug, % "Enviando: " "{BotonVisual:" BotonVisual ",FicheroEjecutar:" FicheroEjecutar "." conf.extension "}"
	}
	else
	{
		Activacion := "Activar" BotonVisual
		GuiControl, Show, %Activacion%
		try
		{
			if(FileExist(A_ScriptDir "\" FicheroEjecutar "." conf.extension))
			{
				if(conf.builtin_ahk)
				{
					
					Run, % A_ScriptDir "\lib\autohotkey.exe " FicheroEjecutar "." conf.extension
				}
				else
				{
					Run, % FicheroEjecutar "." conf.extension
				}
			}
		}
		feedbackEjecucion.push(Activacion)
		SetTimer, OcultarFeedbackEjecucion, 150
	}
}

OcultarFeedbackEjecucion:
	if(feedbackEjecucion.length() = 1)
	{
		SetTimer, OcultarFeedbackEjecucion, Off
	}
	GuiControl, Hide, % feedbackEjecucion[1]
	feedbackEjecucion.remove(1)
return

CreateFolderButton:
	InputBox, nombreCarpetaNueva, Input Folder Name, Input the folder name WITHOUT spaces or weird symbols. Samples: (Programs`,GameFolder`,OBS_Buttons...)
	if(nombreCarpetaNueva != "")
	{
		if(Instr(nombreCarpetaNueva, A_Space))
		{
			MsgBox,,Error, A folder name can not have spaces!`nPlease choose a different name.
			gosub, CreateFolderButton
		}
		nameExists := 0
		StringLower, nombreCarpetaNuevaLower, nombreCarpetaNueva
		for k, v in conf.folderButtons
		{
			StringLower, vLower, v
			if(vLower = nombreCarpetaNuevaLower)
				nameExists := 1
		}
		if(!nameExists)
		{
			conf.folderButtons[BotonActivo] := nombreCarpetaNueva
			gosub, guardarConfig
		}
		else
		{
			MsgBox,,Error, A folder with this name already exists!`nPlease choose a different name.
			gosub, CreateFolderButton
		}
	}
	else
	{
		MsgBox,,Error, Error while creating folder or cancelled.
	}
return

DeleteFolderButton:
	OnMessage(0x44, "OnMsgBox")
	MsgBoxBtn1 = Delete
	MsgBoxBtn2 = Cancel
	MsgBox 0x34, Delete Folder?, This folder may contain other buttons or folders, delete it anyway?
	OnMessage(0x44, "")
	IfMsgBox Yes, {
		OnMessage(0x44, "OnMsgBox")
		MsgBoxBtn1 = Delete them
		MsgBoxBtn2 = Cancel
		MsgBox 0x34, Delete Inside?, You deleted the folder!`nDo you want to also remove buttons/folders that were inside of this folder?`nThis function is experimental, it is recommended that you delete those yourself!`n`nProceed Anyway?
		OnMessage(0x44, "")
		IfMsgBox Yes, {
			if(conf.folderButtons[BotonActivo] != "")
			{
				Loop, Files, % A_ScriptDir "\" conf.folderButtons[BotonActivo] "*.ahk"
				{
					FileDelete, % A_LoopFileFullPath
				}
				Loop, Files, % A_ScriptDir "\resources\img\" conf.folderButtons[BotonActivo] "*.png"
				{
					FileDelete, % A_LoopFileFullPath
				}
			}
		}
		conf.folderButtons.delete(BotonActivo) 
		gosub, guardarConfig
		OnMessage(0x44, "OnMsgBox")
		MsgBoxBtn1 = Delete
		MsgBoxBtn2 = Cancel
		MsgBox 0x34, Delete Icon?, Do you want to also remove this folder icon?
		OnMessage(0x44, "")
		IfMsgBox Yes, {
			FileDelete,./resources/img/%BotonActivo%.png
			DllCall("DeleteObject", "ptr", btnPics[BotonActivo ".png"]) ; Dispose image from memory
			btnPics[BotonActivo ".png"] := ""
			if(EnCarpeta)
			{
				EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
			}
			else
			{
				EstablecerPagina(NumeroPagina)	
			}
		}
	}else{
		return
	}	
return

DeleteButtonFunction:
	if(FileExist(BotonActivo ".ahk"))
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBoxBtn1 = Delete
		MsgBoxBtn2 = Cancel
		MsgBox 0x34, Delete Function?, This button has a function it will be deleted!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			FileDelete, %BotonActivo%.ahk
			OnMessage(0x44, "OnMsgBox")
			MsgBoxBtn1 = Delete
			MsgBoxBtn2 = Cancel
			MsgBox 0x34, Delete Icon?, Do you want to also remove this button icon?
			OnMessage(0x44, "")
			IfMsgBox Yes, {
				FileDelete,./resources/img/%BotonActivo%.png
				DllCall("DeleteObject", "ptr", btnPics[BotonActivo ".png"]) ; Dispose image from memory
				btnPics[BotonActivo ".png"] := ""
				if(EnCarpeta)
				{
					EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
				}
				else
				{
					EstablecerPagina(NumeroPagina)	
				}
			}
		}
	}
return

setStartPossition:
	if(WinExist("Nova Macros Start Pos"))
	{
		WinActivate, Nova Macros Start Pos
	}
	else
	{
		Gui startPos:Add, Text, x8 y8 w61 h23 +0x200, Initial X Pos:
		Gui startPos:Add, Text, x8 y40 w60 h23 +0x200, Initial Y Pos:
		Gui startPos:Add, Edit, x72 y8 w120 h21 vx_Inicial +Center +Number, % conf.x_Inicial
		Gui startPos:Add, Edit, x72 y40 w120 h21 vy_Inicial +Center +Number, % conf.y_Inicial
		Gui startPos:Add, Button, x112 y72 w80 h23 gsaveStartPossition, Set and Save
		Gui startPos:Add, Button, x8 y72 w80 h23 ggetCurrentPos, Get current
		Gui startPos:Show, w200 h103, Nova Macros Start Pos
	}
return

saveStartPossition:
	GuiControlGet, x_Inicial, startPos:, x_Inicial
	GuiControlGet, y_Inicial, startPos:, y_Inicial
	conf.x_Inicial := x_Inicial
	conf.y_Inicial := y_Inicial
	gosub, guardarConfig
	Gui, startPos:Destroy
	WinMove, Nova Macros Client,, % x_Inicial, % y_Inicial
return

getCurrentPos:
	WinGetPos, x, y,,, Nova Macros Client
	GuiControl, startPos:, x_Inicial, % x
	GuiControl, startPos:, y_Inicial, % y
return

guardarConfig:
	if(!conf.online){
		FileDelete, ./conf/config.json
		FileAppend, % JSON_Beautify(BuildJson(conf)), ./conf/config.json
	}
return

guardarConfigCambioOnline:
	FileDelete, ./conf/config.json
	FileAppend, % JSON_Beautify(BuildJson(conf)), ./conf/config.json
return

startPosguiEscape:
startPosguiClose:
	Gui, startPos:Destroy
return

OnMsgBox() {
    DetectHiddenWindows, On
    Process, Exist
    If (WinExist("ahk_class #32770 ahk_pid " . ErrorLevel)) {
        ControlSetText Button1, % MsgBoxBtn1
        ControlSetText Button2, % MsgBoxBtn2
        ControlSetText Button3, % MsgBoxBtn3
        ControlSetText Button4, % MsgBoxBtn4
    }
}

AltTab(){
	global
	; Alt tab replacement, faster, less distracting
	if(conf.enviarAltTabAlPulsarBoton)
	{
		list := ""
		WinGet, id, list
		Loop, %id%
		{
			this_ID := id%A_Index%
			IfWinActive, ahk_id %this_ID%
				continue    
			WinGetTitle, title, ahk_id %this_ID%
			If (title = "")
				continue
			If (!IsWindow(WinExist("ahk_id" . this_ID))) 
				continue
			WinActivate, ahk_id %this_ID%, ,2
				break
		}
	}
}

; Check whether the target window is activation target
IsWindow(hWnd){
    WinGet, dwStyle, Style, ahk_id %hWnd%
    if ((dwStyle&0x08000000) || !(dwStyle&0x10000000)) {
        return false
    }
    WinGet, dwExStyle, ExStyle, ahk_id %hWnd%
    if (dwExStyle & 0x00000080) {
        return false
    }
    WinGetClass, szClass, ahk_id %hWnd%
    if (szClass = "TApplication") {
        return false
    }
    return true
}

SkinForm(Param1 = "Apply", DLL = "", SkinName = ""){
	if(Param1 = Apply){
		DllCall("LoadLibrary", str, DLL)
		DllCall(DLL . "\USkinInit", Int,0, Int,0, AStr, SkinName)
	}else if(Param1 = 0){
		DllCall(DLL . "\USkinExit")
		}
}

GetOut:
	SkinForm(0)
    ExitApp
	

; NETWORKING MODULE
EnviarTCP(txtSnd)
{
    tcpCon.sendText(txtSnd)
}

OnTcpRecv(this)
{
	Activacion := "Activar" this.RecvText()
	GuiControl, Show, %Activacion%
	feedbackEjecucion.push(Activacion)
	SetTimer, OcultarFeedbackEjecucion, 150
}

crearGuiNetworkSettings:
	if(WinExist("Nova Macros Network Settings"))
	{
		WinActivate, Nova Macros Network Settings
	}
	else
	{
		if(conf.online)
			Gui networkSettings:Add, CheckBox, x16 y8 w120 h23 vOnlineChk checked, Online Mode
		else
			Gui networkSettings:Add, CheckBox, x16 y8 w120 h23 vOnlineChk, Online Mode
		Gui networkSettings:Add, Text, x16 y40 w43 h23 +0x200, IP:
		Gui networkSettings:Add, Text, x16 y72 w43 h23 +0x200, Port:
		Gui networkSettings:Add, Text, x16 y104 w43 h23 +0x200, Res Port:
		Gui networkSettings:Add, Edit, +Center x64 y40 w120 h21 vIpTxt, % conf.ip
		Gui networkSettings:Add, Edit, +Center x64 y72 w120 h21 vPortTxt, % conf.port
		Gui networkSettings:Add, Edit, +Center x64 y104 w120 h21 vResourcesPortTxt, % conf.resourcesPort
		Gui networkSettings:Add, Button, x16 y136 w80 h23 gSaveNetworkConfig, SAVE CONFIG
		Gui networkSettings:Add, Button, x104 y136 w80 h23 gConnectToServer, CONNECT
		Gui networkSettings:Add, Text, x0 y168 w214 h2 +0x10 ; Separator
		Gui networkSettings:Add, Text, x8 y169 w191 h23 +Center +0x200 vNetworkStatusInfo, Nova Macros - Network Config
		Gui networkSettings:Show, w208 h192, Nova Macros Network Settings
	}
Return

SaveNetworkConfig:
	GuiControlGet, IpTxt, networkSettings:, IpTxt
	GuiControlGet, PortTxt, networkSettings:, PortTxt
	GuiControlGet, OnlineChk, networkSettings:, OnlineChk
	GuiControlGet, ResourcesPortTxt, networkSettings:, ResourcesPortTxt
	mustReload := 0
	if(OnlineChk != conf.online)
	{
		mustReload := 1
	}
	gosub, loadConfig ; This is needed because when we are online, folder config is the remote server's config, and we don't want to keep it when we switch back to local mode
	conf.online := OnlineChk
	conf.ip := IpTxt
	conf.port := PortTxt
	conf.resourcesPort := ResourcesPortTxt
	gosub, guardarConfigCambioOnline
	GuiControl, networkSettings:+cBlue, NetworkStatusInfo
	GuiControl, networkSettings:Text, NetworkStatusInfo, Config Saved!
	if(mustReload)
	{
		reload
	}
return

ConnectToServer:
	GuiControlGet, OnlineChk, networkSettings:, OnlineChk
	if(!OnlineChk)
	{
		MsgBox, % "Enable online mode first!"
		return
	}
	GuiControlGet, IpTxt, networkSettings:, IpTxt
	GuiControlGet, PortTxt, networkSettings:, PortTxt
	GuiControlGet, ResourcesPortTxt, networkSettings:, ResourcesPortTxt
	GuiControl, networkSettings:+cBlack, NetworkStatusInfo
	GuiControl, networkSettings:Text, NetworkStatusInfo, Connecting...
	tcpCon := new SocketTCP()
	tcpCon.connect(IpTxt, PortTxt)
	tcpCon.onRecv := Func("OnTcpRecv")
	if(tcpCon.errorNM != "")
	{
		serverFound := 0
		GuiControl, networkSettings:+cRed, NetworkStatusInfo
		GuiControl, networkSettings:Text, NetworkStatusInfo, Could not connect!
	}
	else
	{
		serverFound := 1
		gosub, SaveNetworkConfig
		GuiControl, networkSettings:+cGreen, NetworkStatusInfo
		GuiControl, networkSettings:Text, NetworkStatusInfo, Connected to the server!
		gosub, downloadServerProfile
	}
	gosub, setWifiIcon
return

networkSettingsguiClose:
networkSettingsguiEscape:
	Gui, networkSettings:Destroy
return

setWifiIcon:
	Gui, 1:Default
	if(conf.online)
	{
		if(serverFound)
		{
			GuiControl, , wifi_icon, % btnPics["wifi_icon_online.png"] ? "HBITMAP:*" btnPics["wifi_icon_online.png"] : ""
		}
		else
		{
			GuiControl, , wifi_icon, % btnPics["wifi_icon_offline.png"] ? "HBITMAP:*" btnPics["wifi_icon_offline.png"] : ""
		}
	}
	else
	{
		GuiControl, , wifi_icon, % btnPics["wifi_icon_disabled.png"] ? "HBITMAP:*" btnPics["wifi_icon_disabled.png"] : ""
	}
return

downloadServerProfile:
	if(!FileExist(A_ScriptDir "\resources\img\" conf.ip)) ; Nuevo servidor
	{
		MsgBox 0x4, Download Server Resource Pack?, Do you want to try to download the server's Resource Pack?
		IfMsgBox Yes, {
			FileCreateDir, % "./resources/img/" conf.ip
			URLDownloadToFile, % "http://" conf.ip ":" conf.resourcesPort "/resourcePack.7z", % "./resources/img/" conf.ip "/resourcePack.7z"
			URLDownloadToFile, % "http://" conf.ip ":" conf.resourcesPort "/resourcePack_info.txt", % "./resources/img/" conf.ip "/resourcePack_info.txt"
			gosub, descomprimirResourcePack
		}
	}
	else
	{
		server_config := ParseJson(URLToVar("http://" conf.ip ":" conf.resourcesPort "/resourcePack_info.txt"))
		serverMD5 := server_config.resourcePackMD5
		FileRead, localMD5, % "./resources/img/" conf.ip "/resourcePack_info.txt"
		localMD5 := ParseJson(localMD5).resourcePackMD5
		if(serverMD5 != localMD5) ; Reemplazo local pq ha cambiado el MD5
		{
			MsgBox 0x4, Download Server Resource Pack?, Do you want to try to download the server's Resource Pack?
			IfMsgBox Yes, {
				FileRemoveDir, % "./resources/img/" conf.ip, 1
				FileCreateDir, % "./resources/img/" conf.ip
				URLDownloadToFile, % "http://" conf.ip ":" conf.resourcesPort "/resourcePack.7z", % "./resources/img/" conf.ip "/resourcePack.7z"
				URLDownloadToFile, % "http://" conf.ip ":" conf.resourcesPort "/resourcePack_info.txt", % "./resources/img/" conf.ip "/resourcePack_info.txt"
				gosub, descomprimirResourcePack
			}
		}
		gosub, precargaIconosRemotosEnRam
	}
return

descomprimirResourcePack:
	ToolTip, % "Decompressing..."
	RunWait, % """" A_WorkingDir "\lib\7za.exe"" x """ A_WorkingDir "\resources\img\" conf.ip "\resourcePack.7z"" -o"""A_WorkingDir "\resources\img\" conf.ip """",, Hide
	FileDelete, % A_WorkingDir "\resources\img\" conf.ip "\resourcePack.7z"
	reload
return

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

precargaIconosLocalesEnRam:
	; Precarga imágenes de botones en memoria (mucha más rápida la navegación) (qué majo soy, unos comentarios los pongo en inglés y otros en español, tremendo caraalpargata)
	GuiControl, splashScreen:, splashTxt, % "Calculating Resource Count..."
	gosub, vaciarMemoriaIconos
	Loop, Files, ./resources/img/*.png
	{
		i++
	}
	Loop, Files, ./resources/img/*.png
	{
		btnPics[A_LoopFileName] := LoadPicture(A_LoopFileFullPath) ; Images loaded using this method are stored in RAM, to free up assigned image resources -> DllCall("DeleteObject", "ptr", btnPics["image_name.png"])
		GuiControl, splashScreen:, splashTxt, % "[" Round((A_Index/i)*100) "%] Loading Resources: " A_LoopFileFullPath
	}
return

precargaIconosRemotosEnRam:
	GuiControl, splashScreen:, splashTxt, % "Calculating Resource Count..."
	gosub, vaciarMemoriaIconos
	Loop, Files, % "./resources/img/" conf.ip "/*.png"
	{
		i++
	}
	Loop, Files, % "./resources/img/" conf.ip "/*.png"
	{
		btnPics[A_LoopFileName] := LoadPicture(A_LoopFileFullPath) ; Images loaded using this method are stored in RAM, to free up assigned image resources -> DllCall("DeleteObject", "ptr", btnPics["image_name.png"])
		GuiControl, splashScreen:, splashTxt, % "[" Round((A_Index/i)*100) "%] Loading Resources: " A_LoopFileFullPath
	}
return

vaciarMemoriaIconos:
	for, k, v in btnPics
	{
		DllCall("DeleteObject", "ptr", btnPics[k]) ; Dispose image from memory
	}
return

generateBackup:
	Run, % """" A_ScriptDir "\lib\autohotkey.exe"" """ A_ScriptDir "\plugins\backup_nova_macros.ahk"""
return

changeReactiveSetting:
	if(conf.reactiveWindow){
		conf.reactiveWindow := 0
	}else{
		conf.reactiveWindow := 1
	}
	gosub, guardarConfig
	if(conf.reactiveWindow)
	{
		Menu ContextMenuGenerico, Check, Reactive Pages
	}
	else
	{
		Menu ContextMenuGenerico, UnCheck, Reactive Pages
	}
	gosub, setReactiveService
return

setReactiveService:
	if(conf.reactiveWindow){
		SetTimer, setPageByActiveProgram, 333
	}else{
		SetTimer, setPageByActiveProgram, Off
	}
return

setPageByActiveProgram:
	; Only trigger changes and app check when Nova Macros is visible
	DetectHiddenWindows, Off
	if(WinExist("Nova Macros Client"))
	{
		WinGet, activeProcess, ProcessName, A
		if(previousActiveProcess != activeProcess && activeProcess != A_ScriptName){
			previousActiveProcess := activeProcess
			if(conf.programFolder[activeProcess] != ""){
				gosub, setPageByActiveProcess ; This was needed due to the improvements in folder change and reactive service folder change being quicker than pulsarBoton() function
			}
		}
	}
	DetectHiddenWindows, On
return

setPageByActiveProcess:
	CarpetaBoton := conf.programFolder[activeProcess]
	PaginaCarpeta := 0
	EstablecerPaginaCarpeta(CarpetaBoton, PaginaCarpeta)
return

lookForUpdatesOnBootLabel:
	if(conf.lookForUpdates)
	{
		conf.lookForUpdates := 0
		Menu LookForUpdatesMenu, UnCheck, On Boot
	}
	else
	{
		conf.lookForUpdates := 1
		Menu LookForUpdatesMenu, Check, On Boot
	}
	gosub, guardarConfig
return

lookForUpdatesLabel:
	lookForUpdates()
return

dummyLabel:
return

bindFolderToProgramOrWindow:
	OnMessage(0x44, "OnBindDeleteMsgBox")
	MsgBox 0x1, Bind Action, Bind or delete bind?
	OnMessage(0x44, "")

	IfMsgBox OK, {
		Gui bindFolderToProgram:Add, Edit, vfileName x16 y15 w325 h21
		Gui bindFolderToProgram:Add, Button, gSelectFile x344 y14 w120 h23, Select Executable
		Gui bindFolderToProgram:Font, Bold
		Gui bindFolderToProgram:Add, Button, x16 y50 w246 h28 gDetect, + Detect already open program
		Gui bindFolderToProgram:Add, Button, x360 y50 w104 h28 gsetFolderProgramBind, SAVE
		Gui bindFolderToProgram:Show, w472 h87, Bind program to page
	} Else IfMsgBox Cancel, {
		; Delete bind
		programFolderTmp := []
		for exe, folder in conf.programFolder
		{
			if(folder != CarpetaBoton){
				
				programFolderTmp[exe] := folder
			}
		}
		conf.programFolder := programFolderTmp
		gosub, guardarConfig
	}
return

OnBindDeleteMsgBox() {
    DetectHiddenWindows, On
    Process, Exist
    If (WinExist("ahk_class #32770 ahk_pid " . ErrorLevel)) {
        ControlSetText Button1, Bind EXE
        ControlSetText Button2, Unbind
    }
}

SelectFile:
	FileSelectFile, fullFilePath,, %A_Desktop%, Select executable, Executables (*.exe)
	if(fullFilePath != "")
	{
		SplitPath, fullFilePath, fileName, workingDir
		GuiControl, bindFolderToProgram:,fileName, % fileName
	}
Return

Detect:
	MsgBox,,Select Window, 1) Activate a window of the program you want this folder being bound to `n2) Press ENTER
	Hotkey, Enter, DetectOpenProgram, On
return

DetectOpenProgram:
	winget, appPath, processpath, a
	SplitPath, appPath, fileName, workingDir
	Hotkey, Enter, DetectOpenProgram, Off
	GuiControl, bindFolderToProgram:,fileName, % fileName
	WinActivate, Bind program to page
return

setFolderProgramBind:
	GuiControlGet, fileName, bindFolderToProgram:, fileName
	conf.programFolder[fileName] := CarpetaBoton
	gosub, guardarConfig
	Gui, bindFolderToProgram:Destroy
return

bindFolderToProgramEscape:
bindFolderToProgramClose:
	Gui, bindFolderToProgram:Destroy
return

showAboutScreen:
	showAboutScreen("Nova Macros v" ClientVersionNumber, "A multi-purpose macro pannel tailored to be used both in single screen setups, multi screen, touch support and multi machine setups via sockets.")
return

openNovaMacrosFolder:
	Run, % A_ScriptDir
return

loadConfig:
	FileRead, conf, ./conf/config.json
	global conf := ParseJson(conf)
	scriptEditorPath := conf.scriptEditorPath
	StringReplace, scriptEditorPath, scriptEditorPath, \, \\, All
	conf.scriptEditorPath := scriptEditorPath
return