#NoEnv
#SingleInstance Force
SetBatchLines -1
#NoTrayIcon
global buttonName = %0% 
global buttonPath := buttonName ".ahk"

SkinForm(Apply, A_ScriptDir . "\lib\them.dll", A_ScriptDir . "\lib\tm")
OnExit, GetOut

Gui Font, s14, Bai Jamjuree Bold
Gui Add, Radio, x8 y8 w191 h48 Checked vfov86, 86º
Gui Add, Radio, x8 y64 w191 h48 vfov78, 78º
Gui Add, Radio, x8 y120 w191 h48 vfov65, 65º

Gui Show, w207 h176, OBSBOT Set FOV
Return

#If WinActive("OBSBOT Set FOV")
	Enter::gosub, generateScript
#If

GetOut:
GuiEscape:
GuiClose:
	SkinForm(0)
    ExitApp

generateScript:
	GuiControlGet, fov86,, fov86
	GuiControlGet, fov78,, fov78
	GuiControlGet, fov65,, fov65
	if(fov86){
		value := 0
	}else if(fov78){
		value := 1
	}else{
		value := 2
	}
	if FileExist(buttonPath)
	{
		OnMessage(0x44, "OnMsgBox")
		MsgBox 0x34, Overwrite?, This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!
		OnMessage(0x44, "")

		IfMsgBox Yes, {
			Generate(value)
		}
	}
	else
	{
		Generate(value)
	}
return

Generate(value)
{
	src :=
	(
"#NoEnv
#SingleInstance Force
#NoTrayIcon
#Include <setAhk64self>
#Include <OBSBOTController>
#Include <nm_msg>
SetBatchLines, -1
DetectHiddenWindows, On
ifWinNotExist, ahk_exe OBSBOT_Main.exe
{
	nmMsg(""OBSBOT svc not detected!"", 2)
	ExitApp
}
myCam := new OBSBOTController(""127.0.0.1"", 16284)
myCam.SetFOV(" value ")
ExitApp
"
	)
	FileDelete, % buttonPath
	FileAppend, %src%, % buttonPath
	ExitApp
}

SkinForm(Param1 = "Apply", DLL = "", SkinName = ""){
	if(Param1 = Apply){
		DllCall("LoadLibrary", str, DLL)
		DllCall(DLL . "\USkinInit", Int,0, Int,0, AStr, SkinName)
	}else if(Param1 = 0){
		DllCall(DLL . "\USkinExit")
	}
}