Photo Marker v3.5.0 for Windows XP/Vista/7
;By Michael Overmeyer
;Including Modified code from Shaun (http://www.autohotkey.com/forum/viewtopic.php?t=39574)

#SingleInstance force ;; Replace any previous instance
#Persistent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;String List, use it to customize the strings in the program

TITLE = Photo Marker
TITLE_SHORT = Marker
VERSION_NUMBER = v3.5.0

DEVICE_REGISTER_FAIL = Failed to register for this device. (It's probably fine)

CALIBRATION_TITLE = Calibration
CALIBRATION_BUTTON = Calibrate
START_CALIBRATION_PROMPT_STRING = Enter the number of judges and click Calibrate
CALIBRATION_PROMPT_STRING = Please press a button on the keypad for Judge
CALIBRATION_COMPLETE_STRING = Calibration Complete.

DEVICE_ALREADY_ENTERED = This device has already been entered. Try again.

RESET_JUDGES_STRING = This judge has not entered a score for this entry yet.
JUDGE_HAS_SCORED_STRING = This judge has entered a score.

MISSING_SCORE_STRING = Missing a score from Judge

NOT_IN_ARRAY_STRING = Not in array.
NOT_IN_RANGE_STRING = This button is not in the range allowed for this mode.


ENTRY_ACCEPTED = In
ENTRY_REJECTED = Out
ACCEPT_BUTTON_SETTINGS_STRING = Accept Button:
REJECT_BUTTON_SETTINGS_STRING = Reject Button:
APPLY_ACCEPTANCE_SETTINGS_BUTTON = Apply
ACCEPTANCE_SETTINGS_TITLE = Settings
SAME_REJECT_AND_ACCEPT_BUTTON = Error: You can not have the same value for your Accept and Reject buttons
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ACCEPT_BUTTON := 9
REJECT_BUTTON := 1

DetectHiddenWindows, on
OnMessage(0x00FF, "InputMessage") ;whenever you get input from a registered HID, then call the InputMessage function 

SizeofRawInputDeviceList := 8
SizeofRidDeviceInfo := 32
SizeofRawInputDevice := 12

RIM_TYPEMOUSE := 0
RIM_TYPEKEYBOARD := 1
RIM_TYPEHID := 2

RIDI_DEVICENAME := 0x20000007
RIDI_DEVICEINFO := 0x2000000b

RIDEV_INPUTSINK := 0x00000100    ;Takes in input even when you don't have the window in focus

RID_INPUT         := 0x10000003

Gui, Add, Text,, %START_CALIBRATION_PROMPT_STRING%
Gui, Add, Edit
Gui, Add, UpDown, vnumJudges Range1-100, 3
Gui, Add, Radio, Checked vMode, Numeric Scoring
Gui, Add, Radio, , Acceptance Scoring
Gui, Add, Button, Default gCalibrate, %CALIBRATION_BUTTON%
Gui, Show, , %CALIBRATION_TITLE%

HWND := WinExist(ahk_id CALIBRATION_TITLE)        ;Hoping that this works

Res := DllCall("GetRawInputDeviceList", UInt, 0, "UInt *", Count, UInt, SizeofRawInputDeviceList)VarSetCapacity(RawInputList, SizeofRawInputDeviceList * Count)

Res := DllCall("GetRawInputDeviceList", UInt, &RawInputList, "UInt *", Count, UInt, SizeofRawInputDeviceList)

MouseRegistered := 0
KeyboardRegistered := 0

Accepting = 0
inputWait = 1
AcceptingScores = 0

;; From Shaun (http://www.autohotkey.com/forum/viewtopic.php?t=39574) 
;; Modified to remove the GUI, this registers the HID devices with the Script
Loop %Count% {
    Handle := NumGet(RawInputList, (A_Index - 1) * SizeofRawInputDeviceList)
    Type := NumGet(RawInputList, (A_Index - 1) * SizeofRawInputDeviceList + 4)
    if (Type = RIM_TYPEMOUSE)
        TypeName := "RIM_TYPEMOUSE"
    else if (Type = RIM_TYPEKEYBOARD)
        TypeName := "RIM_TYPEKEYBOARD"
    else if (Type = RIM_TYPEHID)
        TypeName := "RIM_TYPEHID"
    else
        TypeName := "RIM_OTHER"
    
    Res := DllCall("GetRawInputDeviceInfo", UInt, Handle, UInt, RIDI_DEVICENAME, UInt, 0, "UInt *", Length)
    
    VarSetCapacity(Name, Length + 2)
    
    Res := DllCall("GetRawInputDeviceInfo", UInt, Handle, UInt, RIDI_DEVICENAME, "Str", Name, "UInt *", Length)
    
    VarSetCapacity(Info, SizeofRidDeviceInfo)    
    NumPut(SizeofRidDeviceInfo, Info, 0)
    Length := SizeofRidDeviceInfo
    
    Res := DllCall("GetRawInputDeviceInfo", UInt, Handle, UInt, RIDI_DEVICEINFO, UInt, &Info, "UInt *", SizeofRidDeviceInfo)
    
    ; Keyboards are always Usage 6, Usage Page 1, Mice are Usage 2, Usage Page 1,
    ; HID devices specify their top level collection in the info block    

    VarSetCapacity(RawDevice, SizeofRawInputDevice)
    NumPut(RIDEV_INPUTSINK, RawDevice, 4)
    NumPut(HWND, RawDevice, 8)
    
    DoRegister := 0
    
    if (Type = RIM_TYPEMOUSE && MouseRegistered = 0)
    {
        DoRegister := 1
        ; Mice are Usage 2, Usage Page 1
        NumPut(1, RawDevice, 0, "UShort")
        NumPut(2, RawDevice, 2, "UShort")
        MouseRegistered := 1
    }
    else if (Type = RIM_TYPEKEYBOARD && KeyboardRegistered = 0)
    {
        DoRegister := 1
        ; Keyboards are always Usage 6, Usage Page 1
        NumPut(1, RawDevice, 0, "UShort")
        NumPut(6, RawDevice, 2, "UShort")
        KeyboardRegistered := 1
    }
    else if (Type = RIM_TYPEHID)
    {
        DoRegister := 1
        NumPut(UsagePage, RawDevice, 0, "UShort")
        NumPut(Usage, RawDevice, 2, "UShort")      
    }
    
    if (DoRegister)
    {
        Res := DllCall("RegisterRawInputDevices", "UInt", &RawDevice, UInt, 1, UInt, SizeofRawInputDevice)
        if (Res = 0)
      {
            MsgBox,48,, %DEVICE_REGISTER_FAIL%
      }
    }
}

return

;; The function to call whenever you get input
InputMessage(wParam, lParam, msg, hwnd)
{
    global
    Res := DllCall("GetRawInputData", UInt, lParam, UInt, RID_INPUT, UInt, 0, "UInt *", Size, UInt, 16)
      
    VarSetCapacity(Buffer, Size)
    
    Res := DllCall("GetRawInputData", UInt, lParam, UInt, RID_INPUT, UInt, &Buffer, "UInt *", Size, UInt, 16)
    
    Type := NumGet(Buffer, 0 * 4)
    Size := NumGet(Buffer, 1 * 4)
    Handle := NumGet(Buffer, 2 * 4)
    Number := NumGet(Buffer, (16 + 6), "UShort")

    if (Type = RIM_TYPEKEYBOARD)
    {
        lastKeyboardHandle = %Handle%    
        if Accepting = 1    ;;If waiting for calibration input
        {
        inputWait = 0
        }
        
    
        if AcceptingScores = 1
        {
            i := findInArray("HIDArray", numJudges, Handle)    ;;Check to make sure it's input from a judge's keypad
            if i = %NOT_IN_ARRAY_STRING%
            {
            }
            else
            {
                
                k:= NumberKVP(Number)
                if k = %NOT_IN_RANGE_STRING%
                {
                }
                else
                {
                    JudgeScoreArray%i% = %k%
                    SoundPlay, *64
                }
            }
        }
        
    }
    return
}


NumberKVP(number)    ;;Takes the input and offsets it to get the number required for that mode
{
    global
    if number between 96 and 105 ;inclusive
    {
        n:= (number - 96)
        if Mode = 1
        {
            if n = 0
            {
                n = 10
            }
            return n
        }
        else if Mode = 2
        {
            if (n = ACCEPT_BUTTON)
            {
                return 1
            }
            else if (n = REJECT_BUTTON)
            {
                return 0
            }
            else
            {
                return NOT_IN_RANGE_STRING
            }
        }
    }
    else
    {
        return NOT_IN_RANGE_STRING
    }
}


Calibrate: ;Is called when you press the Calibrate button
Gui, Submit,    ;gets the variables from the radio buttons / various fields
if (Mode = 1)
{
    Calibrate()
    JudgingFrame()
}
else if (Mode = 2)
{
    AcceptanceButtonSettings()
}
return

Calibrate()
{
    global
    Sleep, 500 ; Small delay to prevent double presses, also looks nice
    loop, %numJudges%
    {
        Gui, 2:Add, Text,, %CALIBRATION_PROMPT_STRING% %A_Index%.
        Gui, 2:Show, , %TITLE_SHORT% %VERSION_NUMBER%
        AcceptingCalibrationInput()
        Sleep, 500    ; Small delay to prevent double presses, also looks nice
        Gui, 2:Destroy
    }
    Gui, 3:Add, Text,, %CALIBRATION_COMPLETE_STRING%
    Gui, 3:Show, , %TITLE_SHORT% %VERSION_NUMBER%
    Sleep, 1000 ; Small delay to prevent double presses, also looks nice
    Gui, 3:Destroy
    
    Gui, Hide
    return
}

AcceptanceButtonSettings()
{
    global
    Gui, 4:Add, Text,, %ACCEPT_BUTTON_SETTINGS_STRING%
    Gui, 4:Add, Edit
    Gui, 4:Add, UpDown, vAButton Range0-9, %ACCEPT_BUTTON%
    Gui, 4:Add, Text,, %REJECT_BUTTON_SETTINGS_STRING%
    Gui, 4:Add, Edit
    Gui, 4:Add, UpDown, vRButton Range0-9, %REJECT_BUTTON%
    Gui, 4:Add, Button, Default gAccept, %APPLY_ACCEPTANCE_SETTINGS_BUTTON%
    Gui, 4:Show,, %ACCEPTANCE_SETTINGS_TITLE%
    
    return
}

Accept:
Gui, 4:Submit
Gui, 4:Destroy
if (RButton = AButton)
{
    MsgBox,16,, %SAME_REJECT_AND_ACCEPT_BUTTON%
    AcceptanceButtonSettings()
    return
}
ACCEPT_BUTTON := Abutton
REJECT_BUTTON := Rbutton

Calibrate()
JudgingFrame()
return


AcceptingCalibrationInput()
{
        global
        inputWait = 1
        Accepting = 1
        while inputWait = 1
        {
        
        }
        
        i := findInArray("HIDArray", numJudges, lastKeyboardHandle)
        if i = %NOT_IN_ARRAY_STRING%
        {
        HIDArray%A_Index% = %lastKeyboardHandle%
        }
        else
        {
            MsgBox, %DEVICE_ALREADY_ENTERED%
            AcceptingCalibrationInput()
        }
        
        HIDArray%A_Index% = %lastKeyboardHandle%
        return
}

JudgingFrame()    ;getting ready to mark another entry
{
    global
    ResetArray("JudgeStatusArray", numJudges, RESET_JUDGES_STRING)
    ResetArray("JudgeScoreArray", numJudges, "-1")
    AcceptingScores = 1
}

End::
nextEntry()
return

Delete::
undoEntry()
return
    
nextEntry()
{
    global
    AcceptingScores = 0
    sleep 500
    j := HaveAllScores("JudgeScoreArray", numJudges)
    if j = -1
    {
        AcceptingScores = 1
        return
    }
    Send {Down}
    Send {Up}
    Send {Delete}
    total = 0
    loop, %numJudges%
    {
        i := JudgeScoreArray%A_Index%
        total := total + i
        Send %i%
        Send {Right}
    }
    
    
    if Mode = 1
    {
        Send %total%
    }
    else if Mode = 2
    {
        i := numJudges / 2
        if (total > i)
        {
            Send %ENTRY_ACCEPTED%
        }
        else
        {
            send %ENTRY_REJECTED%
        }
    }

    Send {Down}

    loop, %numJudges%
    {
        Send {Left}
    }
    JudgingFrame()
    return
}

undoEntry()
{
    global
    Send {Down}
    Send {Up}
    Send {Delete}
    AcceptingScores = 0
    sleep 500
    loop, %numJudges%
    {
        Send {Right}
    }
    Send {Up}
    loop, %numJudges%
    {
        Send {Left}
        Send {Delete}
    }
    JudgingFrame()
    return
}
    
HaveAllScores(Array, size)
{
    global
    loop, %size%
    {
        i := %Array%%A_Index%
        if i = -1
        {
            ToolTip, %MISSING_SCORE_STRING% %A_Index%.
            SetTimer, RemoveToolTip, 1000
            return -1
        }
    }
    return
}


ResetArray(Array, size, resetValue)
{
    global
    loop, %size%
    {
        ;JudgeScoreArray%i% = %k%
        %Array%%A_Index% = %resetValue%
    }
}
return

findInArray(Array, size, target) ;i := findInArray("HIDArray", numJudges, "54396109")
{
    global NOT_IN_ARRAY_STRING
    
    loop, %size%
    {
        i := %Array%%A_Index%
        if target = %i%
        {
            return %A_Index%
        }
    }
    return NOT_IN_ARRAY_STRING
}

RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
    return
    
+Escape::
    ExitApp
    Return
    
GuiClose:
    ExitApp
    return
    
F1::        ;;Help file
Run, open README.txt
Return
    
;Disable all the unused keys on the numpads

NumpadPgUp::
return

NumpadDot::
return

NumpadDel::
return

NumpadDiv::
return

NumpadMult::
return

NumpadAdd::
return

NumpadSub::
return

NumpadEnter::
return

NumpadIns::
return

NumpadEnd::
return

NumpadDown::
return

NumpadPgDn::
return

NumpadLeft::
return

NumpadClear::
return

NumpadRight::
return

NumpadHome::
return

NumpadUp::
return
