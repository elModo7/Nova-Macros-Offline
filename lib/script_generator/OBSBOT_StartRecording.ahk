#NoEnv
#SingleInstance Force
SetBatchLines -1
#NoTrayIcon
global buttonName = %0% 
global buttonPath := buttonName ".ahk"
if FileExist(buttonPath)
{
	OnMessage(0x44, "OnMsgBox")
	MsgBox 0x34, Overwrite?, This button already has a macro file`, do you want to overwrite it?`n`nPrevious function will be lost!
	OnMessage(0x44, "")

	IfMsgBox Yes, {
		Generate()
	}
}
else
{
	Generate()
}
return


Generate()
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
myCam.StartRecording()
ExitApp
"
	)
	FileDelete, % buttonPath
	FileAppend, %src%, % buttonPath
	ExitApp
}