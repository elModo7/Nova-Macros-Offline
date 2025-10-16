#NoEnv
#NoTrayIcon
#SingleInstance Force
SetWorkingDir, %A_ScriptDir%
#Include plugins/spotify/Spotify.ahk
spoofy := new Spotify
ShuffleMode := PlaybackInfo.shuffle_state
ShuffleMode := !ShuffleMode
spoofy.Player.SetShuffle(ShuffleMode)
ExitApp