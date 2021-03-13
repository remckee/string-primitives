TITLE Project 6 - String Primitives and Macros     (Proj6_mckeever.asm)

; Author: Rebecca Mckeever
; Last Modified: 03/13/2021
; OSU email address: mckeever@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: 03/16/2021
; Description: ***

INCLUDE Irvine32.inc

; ---------------------------------------------------------------
; Name: mGetString
;
; 
;
; Preconditions: 
;
; Receives:
; 
; 
; 
;
; returns: 
; ---------------------------------------------------------------
mGetString MACRO     promptStr:REQ, buffer:REQ, bufferSize:REQ, numChars:REQ
    PUSH    EAX                             ; save registers
    PUSH    ECX
    PUSH    EDX

    ; display prompt and read user input
    mDisplayString promptStr
    MOV     EDX, buffer
    MOV     ECX, bufferSize
    CALL    ReadString

    ; move input and number of characters read to appropriate memory locations
    MOV     buffer, EDX
    MOV     numChars, EAX

    POP     EDX                             ; restore registers
    POP     ECX
    POP     EAX
ENDM


; ---------------------------------------------------------------
; Name: mDisplayString
;
; 
;
; Preconditions: 
;
; Receives:
; 
; 
; 
;
; returns: 
; ---------------------------------------------------------------
mDisplayString MACRO inString:REQ
    PUSH    EDX                             ; save register
    
    MOV     EDX, inString
    CALL    WriteString

    POP     EDX                             ; restore register
ENDM


; (insert constant definitions here)
NUM_COUNT = 3
STR_LEN = 100                   ; includes extra bytes to account for user entering multiple leading 0's
MIN_VAL = -80000000h            ; -2^31
MAX_VAL = 7FFFFFFFh             ; 2^31 - 1

.data
    userInput   BYTE    STR_LEN DUP(0)
    intro1      BYTE    "Project 6: Designing low-level I/O procedures by Rebecca Mckeever",
                        13,10,13,10,"Please enter ",0
    intro2      BYTE    " signed decimal integers.",13,10,
                        "Each number must be small enough to fit in a 32 bit register. After you input the ",13,10,
                        "numbers, I will display the numbers entered, their sum, and the average.",13,10,13,10,0
    prompt      BYTE    "Please enter a signed number: ",0
    errorMsg    BYTE    "ERROR: You did not enter a signed number, or your number was too big. Please try again.",13,10,0
    numsLabel   BYTE    13,10,"You entered the following numbers: ",13,10,0
    sumLabel    BYTE    13,10,"The sum of these numbers is: ",0
    aveLabel    BYTE    13,10,"The rounded average is: ",0
    goodbye     BYTE    13,10,"Goodbye, thanks for playing!",13,10,0
    commaSp     BYTE    ", ",0
    numberArr   SDWORD  NUM_COUNT DUP(?)

.code
main PROC
    ; set up framing and call intro
    PUSH    OFFSET intro1
    PUSH    OFFSET intro2
    PUSH    NUM_COUNT
    CALL    intro

    ; set up framing and call getIntegers to get 10 integers from user
    PUSH    NUM_COUNT
    PUSH    MIN_VAL
    PUSH    MAX_VAL
    PUSH    OFFSET prompt
    PUSH    OFFSET errorMsg
    PUSH    OFFSET userInput
    PUSH    SIZEOF userInput
    PUSH    OFFSET numberArr
    CALL    getIntegers
    
    ; set up framing and call displayResults
    PUSH    OFFSET commaSp
    PUSH    OFFSET numsLabel
    PUSH    OFFSET sumLabel
    PUSH    OFFSET aveLabel
    PUSH    NUM_COUNT
    PUSH    OFFSET numberArr
    CALL    displayResults

    ; set up framing and call WriteVal
    ;CALL    WriteVal
    
    Invoke ExitProcess,0    ; exit to operating system
main ENDP


; ---------------------------------------------------------------
; Name: intro
;
; This procedure displays the program title and the name of the author,
; then it displays instructions and a description of the program to the user.
;
; Preconditions: The numerical value input must be DWORD.
;
; Postconditions: None
;
; Receives:
;       [EBP + 4*4] = address of first string to display
;       [EBP + 3*4] = address of second string to display
;       [EBP + 2*4] = numerical value to place between the two strings
;
; Returns: None
; ---------------------------------------------------------------
intro PROC
    PUSH    EBP                             ; save registers
    MOV     EBP, ESP

    ; display first string
    mDisplayString [EBP + 4*4]

    ; display numerical value
    PUSH    [EBP + 2*4]
    CALL    WriteVal

    ; display second string
    mDisplayString [EBP + 3*4]

    MOV     ESP, EBP                        ; restore registers
    POP     EBP
    RET 3*4
intro ENDP


; ---------------------------------------------------------------
; Name: ReadVal
; 
; 
; 
; Preconditions: 
; 
; Postconditions: 
; 
; Receives: 
;       [EBP + 8*4] = minimum value of user input
;       [EBP + 7*4] = maximum value of user input
;       [EBP + 6*4] = the address of a string prompt
;       [EBP + 5*4] = the address of a string error message
;       [EBP + 4*4] = the address of a string to hold user input
;       [EBP + 3*4] = size of the string that holds user input
;       [EBP + 2*4] = the address of an SDWORD
;
; Returns: 
; ---------------------------------------------------------------
ReadVal PROC
    LOCAL   byteCount: DWORD, curChar: DWORD, isNegative: BYTE
    PUSH    EAX                                 ; save registers
    PUSH    EBX
    PUSH    ECX
    PUSH    EDX
    PUSH    EDI
    PUSH    ESI

    MOV     EDI, [EBP + 2*4]
    MOV     ESI, [EBP + 4*4]
    MOV     EBX, 0
    MOV     [EDI], EBX
_getInput:
    MOV     isNegative, 0
    ; call mGetString to get user input
    mGetString [EBP + 6*4], ESI, [EBP + 3*4], byteCount

;    MOV     ESI, [EBP + 4*4]
    MOV     ECX, byteCount
    CMP     ECX, 0
    JE      _invalid

    ; get first character of input string to check for possible sign
    CLD
    LODSB
    MOVZX   EAX, AL
    MOV     curChar, EAX

    CMP     curChar, '+'
    JE      _checkLength
    CMP     curChar, '-'
    JE      _checkLength
    JMP     _checkNumerals

_checkLength:
    CMP     ECX, 1
    JLE     _invalid

    CMP     curChar, '-'
    JNE     _endLoop
    MOV     isNegative, 1
    JMP     _endLoop

_charLoop:
    CLD
    LODSB
    MOVZX   EAX, AL
    MOV     curChar, EAX
    JMP _checkNumerals

_endLoop:
    LOOP    _charLoop
    JMP     _end

_checkNumerals:
    CMP     curChar, '9'
    JG      _invalid
    CMP     curChar, '0'
    JL      _invalid

    SUB     curChar, '0'
    CMP     isNegative, 1
    JNE     _continue
    MOV     EAX, -1
    MOV     EDX, 0
    IMUL    EAX, curChar
    MOV     curChar, EAX

_continue:
    MOV     EAX, [EDI]
    MOV     EBX, 10
    MOV     EDX, 0
    IMUL    EBX
    JO      _invalid
    ADD     EAX, curChar
    JO      _invalid
    MOV     [EDI], EAX
    JMP     _checkPositive

_checkPositive:
    ; check sign to determine which limit to compare to
    CMP     isNegative, 1
    JE      _checkMin

    CMP     EAX, [EBP + 7*4]
    JG      _invalid
    CMP     EAX, 0
    JL      _invalid
 ;   CMP     isNegative, 1
 ;   JNE     _invalid
    JMP     _endLoop

_checkMin:
   ; NEG     EAX
    CMP     EAX, [EBP + 8*4]
    JL      _invalid
    CMP     EAX, 0
    JG      _invalid
    JMP     _endLoop

_invalid:
    MOV     EBX, 0
    MOV     [EDI], EBX
    mDisplayString [EBP + 5*4]
    JMP     _getInput

_end:
    MOV     [EDI], EAX                          ; move possibly negated value
    POP     ESI                                 ; restore registers
    POP     EDI
    POP     EDX
    POP     ECX
    POP     EBX
    POP     EAX
    RET     7*4
ReadVal ENDP


; ---------------------------------------------------------------
; Name: WriteVal
; 
; 
; 
; Preconditions: 
; 
; Postconditions: 
; 
; Receives: 
;       [EBP + 2*4] = the value of an SDWORD
;
; Returns: 
; ---------------------------------------------------------------
WriteVal PROC
    LOCAL   outString[12]: BYTE, inString[12]: BYTE, isNegative: BYTE
    PUSH    EDI                                 ; save registers
    PUSH    ESI
    PUSH    EAX
    PUSH    EBX
    PUSH    ECX
    PUSH    EDX

    ; move local strings and input value into registers
    LEA     ESI, outString
    LEA     EDI, inString
    MOV     EBX, [EBP + 2*4]
    MOV     isNegative, 0                       ; defaults to 0 (positive)

    ; save the addresses of the start of the strings
    PUSH    ESI
    PUSH    EDI

    ; fill local strings with zeros
    MOV     ECX, 12
    MOV     AL, 0
_fillZeros:
    MOV     [ESI], AL
    CLD
    MOVSB
    LOOP    _fillZeros

    ; restore the addresses of the start of the strings
    POP     EDI
    POP     ESI

    ; initialize loop counter and determine next step based
    ; on sign of input value
    MOV     ECX, 0
    CMP     EAX, 0
    JL      _processSign
    JMP     _checkValue

; place negative sign at beginning of both strings
_processSign:
    MOV     isNegative, 1
    MOV     AL, '-'
    MOV     [ESI], AL
    CLD
    MOVSB

; break out of loop if remaining value is zero and not
; first iteration
_checkValue:
    CMP     EBX, 0
    JNE     _processValue
    CMP     ECX, 0
    JE      _processValue
    JMP     _endLoop

; process remaining value into characters
_processValue:
    CDQ
    MOV     EAX, EBX
    MOV     EBX, 10
    IDIV    EBX
    MOV     EBX, EAX
    MOV     EAX, EDX
    
    CMP     ECX, 0                      ; (counter == 0) and (number < 0)
    JNE     _storeCharacter
    CMP     isNegative, 1
    JNE     _storeCharacter
    NEG     EBX                             ; negate after processing one
    NEG     EAX                             ; digit so remaining calculations
                                            ; do not result in a negative value
; determine ascii value and store
_storeCharacter:
    ADD     EAX, '0'
    CLD
    STOSB
    INC     ECX
    JMP     _checkValue

; swap source and destination so that reversed string can be
; copied into string now in destination register; save address of
; beginning of string
_endLoop:
    XCHG    EDI, ESI
    DEC     ESI
    PUSH    EDI

; copy reversed value into EDI in correct order
_reverseString:
    STD
    LODSB
    CLD
    STOSB
    LOOP   _reverseString

    ; restore address of beginning of string; decrement address
    ; to include minus character for negative values
    POP     EDI
    CMP     isNegative, 1
    JNE     _printString
    DEC     EDI

_printString:
    mDisplayString EDI

    POP     EDX                                 ; restore registers
    POP     ECX
    POP     EBX
    POP     EAX
    POP     ESI
    POP     EDI
    RET     4
WriteVal ENDP


; ---------------------------------------------------------------
; Name: getIntegers
; 
; 
; 
; Preconditions: 
; 
; Postconditions: 
; 
; Receives: 
;       [EBP + 9*4] = number of values to get from user
;       [EBP + 8*4] = minimum value of user input
;       [EBP + 7*4] = maximum value of user input
;       [EBP + 6*4] = the address of a string prompt
;       [EBP + 5*4] = the address of a string error message
;       [EBP + 4*4] = the address of a string to hold user input
;       [EBP + 3*4] = size of the string that holds user input
;       [EBP + 2*4] = the address of an array of SDWORDs
;
; Returns: 
; ---------------------------------------------------------------
getIntegers PROC
    LOCAL   number: SDWORD
    PUSH    EAX
    PUSH    EBX
    PUSH    ECX
    PUSH    EDI

    MOV     EDI, [EBP + 2*4]
    MOV     ECX, [EBP + 9*4]
    LEA     EBX, number
    CLD
    
_fillArray:
    ; set up framing and call ReadVal to get an integer from user    
    PUSH    [EBP + 8*4]
    PUSH    [EBP + 7*4]
    PUSH    [EBP + 6*4]
    PUSH    [EBP + 5*4]
    PUSH    [EBP + 4*4]
    PUSH    [EBP + 3*4]
    PUSH    EBX
    CALL    ReadVal
    
    MOV     EAX, number
    STOSD                           ; place value from user in array
 ;   MOV     [EDI], EAX              
 ;   ADD     EDI, 4                  ; TYPE of array 
    LOOP    _fillArray

    POP     EDI
    POP     ECX
    POP     EBX
    POP     EAX
    RET     8*4
getIntegers ENDP


; ---------------------------------------------------------------
; Name: displayResults
; 
; 
; 
; Preconditions: 
; 
; Postconditions: 
; 
; Receives: 
;       [EBP + 7*4] = the address of a string delimiter to display 
;                       between numbers in list
;       [EBP + 6*4] = the address of a string label for the list of numbers
;       [EBP + 5*4] = the address of a string label for the sum
;       [EBP + 4*4] = the address of a string label for the average
;       [EBP + 3*4] = number of values received from user
;       [EBP + 2*4] = the address of an array of SDWORDs
;
; Returns: 
; ---------------------------------------------------------------
displayResults PROC
    LOCAL   sum: SDWORD, average: SDWORD 
    PUSH    EAX                     ; save registers
    PUSH    ECX                     
    PUSH    EDX
    PUSH    ESI
    
    ; initialize sum, average, loop counter, and array pointer
    MOV     sum, 0
    MOV     average, 0
    MOV     ECX, [EBP + 3*4]
    MOV     ESI, [EBP + 2*4]

    ; display label for list of numbers
    mDisplayString [EBP + 6*4]

; step through array of numbers; for each value, add to sum and display it
_processArray:
    CLD
    LODSD                           ; move current value into accumulator
    ADD     sum, EAX

    ; call WriteVal to display value within list
    PUSH    EAX
    CALL    WriteVal
    CMP     ECX, 1                  ; skip displaying delimiter after last value
    JE      _endLoop                
    mDisplayString [EBP + 7*4]      ; display delimiter
_endLoop:
    LOOP    _processArray

    ; display label for sum and call WriteVal to display sum
    mDisplayString [EBP + 5*4]
    MOV     EAX, sum
    PUSH    EAX
    CALL    WriteVal

    ; display label for average
    mDisplayString [EBP + 4*4]

    ; calculate and display average
    MOV     EBX, [EBP + 3*4]
    CDQ
    IDIV    EBX
    IMUL    EDX, 2
    CMP     EDX, 0
    JE      _displayAverage
    JL      _negative
    JMP     _positive

_negative:
    CMP     EDX, EBX
    JLE     _roundDown
    JMP     _displayAverage

_roundDown:
    DEC     EAX
    JMP     _displayAverage

_positive:
    CMP     EDX, EBX
    JGE     _roundUp
    JMP     _displayAverage

_roundUp:
    INC     EAX
    JMP     _displayAverage

_displayAverage:
    PUSH    EAX
    CALL    WriteVal

    POP     ESI                     ; restore registers
    POP     EDX
    POP     ECX
    POP     EAX
    RET     6*4
displayResults ENDP


END main
