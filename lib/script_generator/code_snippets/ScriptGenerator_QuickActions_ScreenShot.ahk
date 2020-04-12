#NoTrayIcon
#NoEnv
#SingleInstance Force
SetBatchLines -1
Send, {LWin Down}
Sleep, 30
Send, {PrintScreen Down}
Sleep, 30
Send, {PrintScreen Up}
Sleep, 30
Send, {LWin Up}
Sleep, 30
Run, C:\Users\%A_UserName%\Pictures\Screenshots