;Photo Marker for Windows XP/Vista/7
;By Michael Overmeyer
;Including Modified code from Shaun (http://www.autohotkey.com/forum/viewtopic.php?t=39574)

#SingleInstance force ;; Replace any previous instance
#Persistent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;String List, use it to customize the strings in the program

TITLE = Photo Marker
TITLE_SHORT = Marker
VERSION_NUMBER = v4.0.0

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

;https://msdn.microsoft.com/en-us/library/aa383751%28VS.85%29.aspx
;BOOL: A Boolean variable (should be TRUE or FALSE). "typedef int BOOL;"
;DWORD: A 32-bit unsigned integer. The range is 0 through 4294967295 decimal. "typedef unsigned long DWORD;"
;HANDLE: A handle to an object. "typedef PVOID HANDLE;"
;HWND: A handle to a window. "typedef HANDLE HWND;"
;INT: A 32-bit signed integer. The range is -2147483648 through 2147483647 decimal. "typedef int INT;"
;LPVOID: A pointer to any type. "typedef void *LPVOID;"
;PVOID: A pointer to any type. "typedef void *PVOID;"
;PUINT: A pointer to a UINT. "typedef UINT *PUINT;"
;SHORT: A 16-bit integer. The range is –32768 through 32767 decimal. "typedef short SHORT;"
;UINT: An unsigned INT.
;USHORT: An unsigned SHORT.	"typedef unsigned short USHORT;"
;WPARAM: A message parameter. "typedef UINT_PTR WPARAM;"

SizeOfBOOL := 4
SizeOfDWORD := 4
SizeOfHANDLE := A_PtrSize
SizeOfHWND := SizeOfHANDLE
SizeOfPUINT := A_PtrSize
SizeOfLPVOID := A_PtrSize
SizeOfUINT := 4
SizeOfULONG := 4
SizeOfUSHORT := 2
SizeOfWPARAM := A_PtrSize

SizeofRawInputDeviceList := 16 ;TODO: Figure out why this isn't 12 instead of 16. Should it not be SizeOfHANDLE + SizeOfDWORD? ;HANDLE hDevice + DWORD dwType

SizeofRidDeviceInfoMouse := SizeOfDWORD + SizeOfDWORD + SizeOfDWORD + SizeOfBOOL ; DWORD dwId; DWORD dwNumberOfButtons; DWORD dwSampleRate; BOOL fHasHorizontalWheel;
SizeofRidDeviceInfoKeyboard := SizeOfDWORD * 6 ;DWORD dwType; DWORD dwSubType; DWORD dwKeyboardMode; DWORD dwNumberOfFunctionKeys; DWORD dwNumberOfIndicators; DWORD dwNumberOfKeysTotal;
SizeofRidDeviceInfoHID := SizeOfDWORD + SizeOfDWORD + SizeOfDWORD + SizeOfUSHORT + SizeOfUSHORT ;DWORD  dwVendorId; DWORD  dwProductId; DWORD  dwVersionNumber; USHORT usUsagePage; USHORT usUsage;
MaxOfFirstTwo := SizeofRidDeviceInfoMouse > SizeofRidDeviceInfoKeyboard ? SizeofRidDeviceInfoMouse : SizeofRidDeviceInfoKeyboard
MaxOfSecondTwo := SizeofRidDeviceInfoKeyboard > SizeofRidDeviceInfoHID ? SizeofRidDeviceInfoKeyboard : SizeofRidDeviceInfoHID
MaxRidDeviceUnionLength := MaxOfFirstTwo > MaxOfSecondTwo ? MaxOfFirstTwo : MaxOfSecondTwo

SizeofRidDeviceInfo := SizeOfDWORD + SizeOfDWORD + MaxRidDeviceUnionLength ;DWORD cbSize; DWORD dwType; union { RID_DEVICE_INFO_MOUSE mouse; RID_DEVICE_INFO_KEYBOARD keyboard; RID_DEVICE_INFO_HID hid;};

SizeofRawInputDevice := SizeOfUSHORT + SizeOfUSHORT + SizeOfDWORD + SizeOfHWND ;USHORT usUsagePage; USHORT usUsage; DWORD  dwFlags; HWND hwndTarget;

SizeOfRawInputHeaderStructure := SizeOfDWORD + SizeOfDWORD + SizeOfHANDLE + SizeOfWPARAM ;DWORD  dwType; DWORD  dwSize; HANDLE hDevice; WPARAM wParam;

RIM_TYPEMOUSE := 0
RIM_TYPEKEYBOARD := 1
RIM_TYPEHID := 2

RIDI_DEVICENAME := 0x20000007
RIDI_DEVICEINFO := 0x2000000b

RIDEV_INPUTSINK := 0x00000100

RID_INPUT       := 0x10000003

Gui, Add, Text,, %START_CALIBRATION_PROMPT_STRING%
Gui, Add, Edit
Gui, Add, UpDown, vnumJudges Range1-100, 3
Gui, Add, Radio, Checked vMode, Numeric Scoring
Gui, Add, Radio, , Acceptance Scoring
Gui, Add, Button, Default gCalibrate, %CALIBRATION_BUTTON%
Gui, Show, , %CALIBRATION_TITLE%

HWND := WinExist(ahk_id CALIBRATION_TITLE)        ;Hoping that this works

Res := DllCall("GetRawInputDeviceList", UInt, 0, "UInt *", Count, UInt, SizeofRawInputDeviceList)

VarSetCapacity(RawInputList, SizeofRawInputDeviceList * Count)

Res := DllCall("GetRawInputDeviceList", UInt, &RawInputList, "UInt *", Count, UInt, SizeofRawInputDeviceList)

MouseRegistered := 0
KeyboardRegistered := 0

Accepting = 0
inputWait = 1
AcceptingScores = 0

;; From Shaun (http://www.autohotkey.com/forum/viewtopic.php?t=39574) 
;; Modified to remove the GUI
;; This registers the HID devices so that whenever we get input from any of them, this script gets notified.
Loop %Count% {
    Type := NumGet(RawInputList, ((A_Index - 1) * SizeofRawInputDeviceList) + SizeOfHANDLE, "Int")

    ; Keyboards are always Usage 6, Usage Page 1, Mice are Usage 2, Usage Page 1,
    ; HID devices specify their top level collection in the info block    

    VarSetCapacity(RawDevice, SizeofRawInputDevice)
    NumPut(RIDEV_INPUTSINK, RawDevice, SizeOfUSHORT*2)
    NumPut(HWND, RawDevice, (SizeOfUSHORT*2) + SizeOfDWORD)
    
    DoRegister := 0

    if (Type = RIM_TYPEKEYBOARD && KeyboardRegistered = 0)
    {
        DoRegister := 1
        ; Keyboards are always Usage 6, Usage Page 1
        NumPut(1, RawDevice, 0, "UShort")
        NumPut(6, RawDevice, 2, "UShort")
        KeyboardRegistered := 1
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
    
    Res := DllCall("GetRawInputData", UInt, lParam, UInt, RID_INPUT, UInt, 0, "UInt *", Size, UInt, SizeOfRawInputHeaderStructure)
    
    VarSetCapacity(Buffer, Size)
   
    Res := DllCall("GetRawInputData", UInt, lParam, UInt, RID_INPUT, UInt, &Buffer, "UInt *", Size, UInt, SizeOfRawInputHeaderStructure)

    Type := NumGet(Buffer, 0, "Int")
    Size := NumGet(Buffer, SizeOfDWORD, "Int")
    Handle := NumGet(Buffer, SizeOfDWORD * 2, "Int")
    
    if (Type = RIM_TYPEKEYBOARD)
    {
        VKey := NumGet(Buffer, (SizeOfRawInputHeaderStructure + 6), "UShort")
        lastKeyboardHandle = %Handle%
        if Accepting = 1    ;;If waiting for calibration input
        {
            inputWait = 0
        }
        
        if AcceptingScores = 1
        {
            i := findInArray("HIDArray", numJudges, Handle)    ;;Check to make sure it's input from a judge's keypad
            if i != %NOT_IN_ARRAY_STRING%
            {
                k := NumberKVP(VKey)
                if k != %NOT_IN_RANGE_STRING%
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
