;~ USAGE
; SplashScreen("splash.png", 3000, 460, 160, 0, 0, true)
global splashTxt

SplashScreen(imageDir, time, ancho, alto, posX, posY, centrada){
	global ClientVersion
	Gui, SplashScreen:+ToolWindow -DPIScale -Caption +HwndSplashScreen +E0x02080000
	Gui, SplashScreen:Font, cGray
	Gui, SplashScreen:Add, Text, x8 y142 w531 h23 +BackgroundTrans vsplashTxt
	Gui, SplashScreen:Add, Text, x8 y5 w531 h23 +BackgroundTrans +Right, %ClientVersion%
	Gui, SplashScreen:Add, Text, x8 y5 w531 h23 +BackgroundTrans +Left, AutoHotkey v%A_AhkVersion%
	Gui, SplashScreen:Add, Picture, x0 y0 w%ancho% h%alto% gMoverVentana, %imageDir%

	if(centrada){
		Gui SplashScreen:Show, w%ancho% h%alto%, SplashImage
	}else{
		Gui SplashScreen:Show, x%posX% y%posY% w%ancho% h%alto%, SplashImage
	}
	;~ Sleep, %time%
	;~ Gui, %SplashScreen%:Destroy
	Return
}