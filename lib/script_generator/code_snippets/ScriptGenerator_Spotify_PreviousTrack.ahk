#NoEnv
#NoTrayIcon
#SingleInstance Force
SetWorkingDir, %A_ScriptDir%
#Include plugins/spotify/Spotify.ahk
spoofy := new Spotify
spoofy.Player.LastTrack()
ExitApp