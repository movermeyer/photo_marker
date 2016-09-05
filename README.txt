Photo Marker by Michael Overmeyer
Acknowledgements: Shaun (http://www.autohotkey.com/forum/viewtopic.php?t=39574)

Calibration
1. Use the up and down arrows with your mouse or your keyboard to enter the number of judges.
2. Choose your scoring mode by selecting the appropriate radio button.
    2a. When Numeric Scoring Mode is chosen, you can also set some additional parameters:
        "Minimum score a judge can enter" = The program will complain if a judge tries to enter a score that is lower than this value.
        "Maximum score a judge can enter" = The program will complain if a judge tries to enter a score that is greater than this value.
            "Key '0' means 10?" checkbox = If checked, when a judge presses the '0' key, a score of 10 will be recorded. Only available if the maximum judge score is set to 10.
        "Maximum total score for an entry" = The program will scale the total of all the judges' scores so that the entry is scored against this total.
3. Click the Calibrate button.
    3b. If you have chosen "Acceptance Scoring", a dialog will appear asking you to choose buttons to represent the Accept and Reject buttons. Change the values to your liking and click Apply.
4. When prompted, press any key on the number pad for that judge.
5. The Calibration Complete window will appear briefly and then the program will minimize to the taskbar.
You are now ready to begin judging

Judging

1. Open the Excel (or spreadsheet) file you want to record the scores in.
2. Select a cell in the 1st judge’s column.

Numeric Scoring Mode:
    In this Mode, judges press the buttons corresponding to the score that they wish to give.
    
    Judges can enter any score they like. However, if they go over the maximum score the are allowed to enter (as defined in the Configuration stage),
    the program will truncate the score so it fits within the maximum score.
    
    For example, imagine that the maximum socre a judge could enter was configured as 472.
        - If the judge presses 4, we store the character '4'
        - If the judge then presses 7, we store the characters '47'
        - If the judge then presses 3, we truncate the buffer to characters '73', since '473' is larger than the maxScore.

    If a judge believes that they made a mistake, they can press the '.' (ie. dot/period/decimal) key at any time to clear their score.
    They can then try again to enter their score.
    The judges can change their scores as many times as they want, only the last score entered will register.
        
    When 0 means 10:
        If the "Key '0' means 10?" checkbox was checked during the "Calibration" stage (note that this requires the maximum score to be 10), 
        pressing zero will register as a score of 10. If you need to score a 0, have the scorekeeper enter it manually using their keyboard.
    
Acceptance Scoring Mode:
    In this Mode, Judges press the Accept or Reject buttons to indicate whether a photo should be accepted or rejected 
    Photos that are accepted by less than half the judges receive an "Out", otherwise they receive an "In"

The judges can change their scores as many times as they want, only the last score entered will register.

3. When all the judges have entered a score, press the END key on the scorekeeper’s keyboard.
4. Should a mistake occur and you need to redo the scoring of the previous entry, simply press the DELETE key on the scorekeeper’s keyboard.

Closing the Program
    Pressing the SHIFT and ESC keys together at any point in the program will close the marking program.
    Alternatively, you can click on the X in the top-right corner of the window, or right-click on the icon in the taskbar tray and click Exit