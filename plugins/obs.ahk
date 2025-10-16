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
		Run, %A_ScriptDir%\lib\autohotkey.exe """ A_ScriptDir "\plugins\obs_sound_control\obs_sound_panel.ahk"""
		)
		FileAppend, % scriptContent, % "" BotonActivo ".ahk"
	}
return