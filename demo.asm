; DEMO.asm

ORG 0

	; Get and store the switch values
    
	START: 
    ;CALL DELAY
    IN     Switches
    JZERO START
    ADDI -3
    JPOS START
    ADDI 1
    STORE COMMAND
    LOADI 1
    OUT LEDs
	TAKE_FIRST: ;CALL DELAY
    IN     Switches
    JZERO TAKE_FIRST
    STORE op1
    LOADI 2
    OUT LEDs
    TAKE_SECOND: ;CALL DELAY
    IN     Switches
    JZERO TAKE_SECOND
    STORE op2
    LOADI 3
    OUT LEDs
    LOAD COMMAND
    JPOS RUN_MOD
    JZERO RUN_GCD
    
    JUMP DONE
    RUN_MOD:
    
    JUMP DONE
    RUN_GCD:
    
    DONE:
    OUT HEX0
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
op1:	DW 0
op2:
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

