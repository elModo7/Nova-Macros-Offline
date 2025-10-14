; Version: 0.2
global txtNMMsg
nmMsg(nmMsg,time:=1,rainbow:=0,color:="FFFFFF")
{
	oldDetectHiddenWindowsValue := A_DetectHiddenWindows
	DetectHiddenWindows, Off
	if(WinExist("Nova Macros Client"))
	{
		WinGetPos,X,Y,,,Nova Macros Client
		nfX := X
		nfY := Y + 500
		Gui nmMsg:+ToolWindow -Caption +AlwaysOnTop
		Gui nmMsg:Color, Black
		Gui nmMsg:Font, s24 c%color%, Press Start 2P
		Gui nmMsg:Add, Text, vtxtNMMsg x24 y48 w1024 h60 +0x200 +Center +BackgroundTrans, % nmMsg
		Gui nmMsg:Show, x%nfX% y%nfY% w1024 h159 NoActivate,msgNovaMacros
		WinSet, TransColor, Black,msgNovaMacros
		if(rainbow)
		{
			Loop, % time
			{
				GuiControl, nmMsg: +cfb0505 +Redraw, txtNMMsg
				Sleep, 100
				GuiControl, nmMsg: +cfb7607 +Redraw, txtNMMsg
				Sleep, 100
				GuiControl, nmMsg: +cf4ea07 +Redraw, txtNMMsg
				Sleep, 100
				GuiControl, nmMsg: +c61f205 +Redraw, txtNMMsg
				Sleep, 100
				GuiControl, nmMsg: +c00f6cb +Redraw, txtNMMsg
				Sleep, 100
			}
		}
		else
		{
			Sleep, 1000 * time
		}
		Gui, nmMsg: Destroy
	}
	DetectHiddenWindows, % A_DetectHiddenWindows
}