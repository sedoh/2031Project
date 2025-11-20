; TEMP.asm

ORG 0

    ; Get and store the switch values
    
    START: ;CALL DELAY
    ;IN Switches
    LOADI 3
    JZERO START
    ADDI -3
    JPOS START
    ADDI 1
    STORE COMMAND
    LOADI 1
    OUT LEDs
    TAKE_FIRST: ;CALL DELAY
    ;IN Switches
    LOADI 40
    JZERO TAKE_FIRST
    STORE op1
    LOADI 2
    OUT LEDs
    TAKE_SECOND: ;CALL DELAY
    ;IN Switches
    LOADI 6
    JZERO TAKE_SECOND
    STORE op2
    LOADI 3
    OUT LEDs
    LOAD COMMAND
    JPOS RUN_MOD
    JZERO RUN_GCD
	 
    LOAD op1
    OUT ID_A
    LOAD op2
    OUT ID_B
    LOADI 1
    OUT ID_START
    WAIT_ID: IN ID_DONE
    JZERO WAIT_ID
    IN ID_RESULT
    JUMP DONE
	 
    RUN_MOD:
    LOAD op1
    OUT MOD_A
    LOAD op2
    OUT MOD_B
    LOADI 1
    OUT MOD_START
    WAIT_MOD: IN MOD_DONE
    JZERO WAIT_MOD
    IN MOD_RESULT
    JUMP DONE
	 
    RUN_GCD:
    LOAD op1
    OUT GCD_A
    LOAD op2
    OUT GCD_B
    LOADI 1
    OUT GCD_START
    WAIT_GCD: IN GCD_DONE
    JZERO WAIT_GCD
    IN GCD_RESULT
	 
    DONE: OUT HEX0
    FINISH: JUMP FINISH



Delay:
	OUT    Timer
WaitingLoop:
	IN     Timer
	ADDI   -50
	JNEG   WaitingLoop
	RETURN



; Variables
Pattern:   DW 0
COMMAND:   DW 0
op1:	   DW 0
op2:       DW 0
; Useful values
Bit0:      DW &B0000000001
Bit9:      DW &B1000000000

mask:	DW 1
tot:	DW 0
res:	DW 0
LED:	DW 0

; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005

; GCD Constants
GCD_A: EQU &H90
GCD_B: EQU &H91
GCD_START: EQU &H92
GCD_RESULT: EQU &H93
GCD_DONE: EQU &H94

; MOD Constants
MOD_A: EQU &H95
MOD_B: EQU &H96
MOD_START: EQU &H97
MOD_RESULT: EQU &H98
MOD_DONE: EQU &H99

; Integer Division Constants
ID_A: EQU &H9A
ID_B: EQU &H9B
ID_START: EQU &H9C
ID_RESULT: EQU &H9D
ID_DONE: EQU &H9E