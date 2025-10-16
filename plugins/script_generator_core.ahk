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