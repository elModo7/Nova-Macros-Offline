#NoEnv
#NoTrayIcon
#SingleInstance Force
SetWorkingDir, %A_ScriptDir%
#Include plugins/spotify/Spotify.ahk
spoofy := new Spotify
PlaybackInfo := spoofy.Player.GetCurrentPlaybackInfo()
VolumePercentage := PlaybackInfo.Device.Volume
Increment := 10
if(VolumePercentage + Increment <= 100)
  VolumePercentage := VolumePercentage + Increment
spoofy.Player.SetVolume(VolumePercentage)
ExitApp