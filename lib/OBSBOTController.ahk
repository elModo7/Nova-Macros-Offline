; Version 0.2
; Uses UDP Server
; Requires AHK64
class OBSBOTController {
    ; Constructor
    __New(ip, port) {
        this.ip := ip
        this.port := port
        DllCall("LoadLibrary", "Str", "lib/OSC2AHKv1.2.dll", "Ptr")
    }

    ; Send Recording Start Command
    StartRecording() {
        addr := "/OBSBOT/WebCam/General/SetPCRecording"
        DllCall("OSC2AHKv1.2.dll\sendOscMessageInt", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", 1)
    }

    ; Send Recording Stop Command
    StopRecording() {
        addr := "/OBSBOT/WebCam/General/SetPCRecording"
        DllCall("OSC2AHKv1.2.dll\sendOscMessageInt", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", 0)
    }   

    ; Take Camera Photo (1->PC Snapshot)
    TakePhoto() {
        addr := "/OBSBOT/WebCam/General/PCSnapshot"
        DllCall("OSC2AHKv1.2.dll\sendOscMessageInt", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", 1)
    }

    ; Wake Camera
    Wake() {
        addr := "/OBSBOT/WebCam/General/WakeSleep"
        DllCall("OSC2AHKv1.2.dll\sendOscMessageInt", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", 1)
    }

    ; Put Camera to Sleep
    Sleep() {
        addr := "/OBSBOT/WebCam/General/WakeSleep"
        DllCall("OSC2AHKv1.2.dll\sendOscMessageInt", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", 0)
    }

    ; Reset Camera Gimbal
    ResetGimbal() {
        addr := "/OBSBOT/WebCam/General/ResetGimbal"
        DllCall("OSC2AHKv1.2.dll\sendOscMessageInt", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", 0)
    }    
    
    ; Set Camera Zoom (0 - 100)
    SetZoom(value) {
        addr := "/OBSBOT/WebCam/General/SetZoom"
        DllCall("OSC2AHKv1.2.dll\sendOscMessageInt", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", value)
    }   

    ; Set Camera FOV (0->86°；1->78°；2->65°)
    SetFOV(value) {
        addr := "/OBSBOT/WebCam/General/SetView"
        DllCall("OSC2AHKv1.2.dll\sendOscMessageInt", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", value)
    }
    
    ; Set Camera Mirror (0->Not Mirror; 1->Mirror)
    SetMirror(value) {
        addr := "/OBSBOT/WebCam/General/SetMirror"
        DllCall("OSC2AHKv1.2.dll\sendOscMessageInt", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", value)
    }
    
    ; Set Camera AI Mode (0->No Tracking；1->Normal Tracking；2->Upper Body；3->Close-up；4->Headless；5->Lower Body；6->Desk Mode；7->Whiteboard；8->Hand；9->Group)
    SetTrackingMode(value) {
        addr := "/OBSBOT/WebCam/Tiny/SetTrackingMode"
        DllCall("OSC2AHKv1.2.dll\sendOscMessageInt", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", value)
    }    
    
    ; Set Camera AI Lock / Unlock (1->Target lock; 0->Target unlock)
    SetAILock(value) {
        addr := "/OBSBOT/WebCam/Tiny/ToggleAILock"
        DllCall("OSC2AHKv1.2.dll\sendOscMessageInt", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", value)
    }
    
    ; Set Camera Tracking Mode (0->Headroom；1->Standard；2->Motion)
    SetAIMode(value) {
        addr := "/OBSBOT/WebCam/Tiny/SetAiMode"
        DllCall("OSC2AHKv1.2.dll\sendOscMessageInt", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", value)
    }

    ; Set Custom Coords (0 - 90, -129 - 129, -59 - 59)
    SetGimbal(speed, pan, pitch) {
        addr := "/OBSBOT/WebCam/General/SetGimMotorDegree"
        
        ; Indefinite number of params example
        DllCall("OSC2AHKv1.2.dll\sendOscMessageInts", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", 3, "Int", speed, "Int", pan, "Int", pitch) ; Requires to specify the amount of params
        
        ; 3 Fixed Parameters example
        ;~ DllCall("OSC2AHKv1.2.dll\sendOscMessageInt3", "AStr", this.ip, "UInt", this.port, "AStr", addr, "Int", speed, "Int", pan, "Int", pitch)
        
        ; Alternative mode with exe
        ;~ Run, % "./osc-utility_0.2.1_windows_amd64.exe message --host " this.ip " --address /OBSBOT/WebCam/General/SetGimMotorDegree --port " this.port " --float " speed "`," pan "`," pitch,,Hide
    }
}