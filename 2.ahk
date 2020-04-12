#NoEnv
#SingleInstance, Force
SetBatchLines, -1
#NoTrayIcon
SetWorkingDir C:\Windows\System32

global Ejecutable := "mspaint.exe"

IfWinExist, ahk_exe %Ejecutable%
{
	WinActivate, ahk_exe %Ejecutable%
}
else
{
	Run, C:\Windows\System32\mspaint.exe
}