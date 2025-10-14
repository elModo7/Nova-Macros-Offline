#NoEnv
SetWorkingDir, %A_ScriptDir%
; Coge la fecha y hora
FormatTime, CurrentDateTime,, yyyyMMdd_HHmm
; Get Parent Folder Full Path
FolderParent := SubStr(A_ScriptDir, 1, InStr(SubStr(A_ScriptDir,1,-1), "\", 0, 0)-1)
NovaMacrosFolder := SubStr(FolderParent, 1, InStr(SubStr(FolderParent,1,-1), "\", 0, 0)-1)
BackupFolder := SubStr(NovaMacrosFolder, 1, InStr(SubStr(NovaMacrosFolder,1,-1), "\", 0, 0)-1)
ToolTip, Creating Nova Macros Backup:`nThis might take a while...
RunWait, ..\lib\7za.exe a "%NovaMacrosFolder%\Nova Macros %CurrentDateTime%.7z" -m0=LZMA2 -mx=5 -mmt=on -aoa -mfb=64 "%FolderParent%",, Hide
ToolTip, Backup Created Successfully!
;~ MsgBox, Backup creada con éxito! `nRuta de la carpeta comprimido: `n"%NovaMacrosFolder%\Nova Macros %CurrentDateTime%.7z"
Run, explorer.exe /select`,"%NovaMacrosFolder%\Nova Macros %CurrentDateTime%.7z"
Sleep, 1000
ExitApp