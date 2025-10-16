; Autoelevates the script sending the new instance all the params from the previous instance
if (A_PtrSize == 4){
	Run, % "lib/autohotkey64.exe " """" A_ScriptFullPath """ " A_Args[1]
	ExitApp
}