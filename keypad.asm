;*******************************************************************
; EE465: Microcontroller Applications
; Montana State University, Bozeman
; by Aaron Jense
;
; Polls keypad until a key is pressed and detected.
; The keypress is sent over I2C for slave B to display LED pattern.                                            *
;*******************************************************************
            INCLUDE 'derivative.inc'
   			XDEF POLL_KEYPAD
            XREF DEBOUNCE_50ms, DELAY_LOOP
			XREF BLINK, IIC_MSG_TX, BYTES_LEFT
MY_ZEROPAGE: SECTION  SHORT
	MPR:				DS.B 1
	KEY_VALUE:			DS.B 1
	COLUMN_CURRENT:		DS.B 1
	ROW_CURRENT: 		DS.B 1
	KEY_BYTE:			DS.B 1
	MAX_IX:				DS.B 1
	DELAY: 	    		DS.B 2
	ROW_0:		EQU %00100000
	ROW_1:		EQU %00010000
	ROW_2:		EQU %00001000
	ROW_3:		EQU %00000100
	COL_0:		EQU	%00001000
	COL_1:		EQU	%00000100
	COL_2:		EQU	%00000010
	COL_3:		EQU	%00000001
ROM_VAR: SECTION
	KEY_TABLE:		DC.B ROW_0+COL_0,'1'
					DC.B ROW_1+COL_0,'4'
					DC.B ROW_2+COL_0,'7'
					DC.B ROW_3+COL_0,'*'
					DC.B ROW_0+COL_1,'2'
					DC.B ROW_1+COL_1,'5'
					DC.B ROW_2+COL_1,'8'
					DC.B ROW_3+COL_1,'0'
					DC.B ROW_0+COL_2,'3'
					DC.B ROW_1+COL_2,'6'
					DC.B ROW_2+COL_2,'9'
					DC.B ROW_3+COL_2,'#'
					DC.B ROW_0+COL_3,'A'
					DC.B ROW_1+COL_3,'B'
					DC.B ROW_2+COL_3,'C'
					DC.B ROW_3+COL_3,'D'
MyCode:     SECTION
main:
POLL_KEYPAD:
			; inits
			LDHX #0
			LDA #0
			STA PTAD
			STA KEY_VALUE
			STA MAX_IX
			STA KEY_BYTE
			LDA PTBD
			AND	#%11000011
			STA	PTBD
			
			;poll routine
			BSET PTBD_PTBD5, PTBD
			JSR	DEBOUNCE_50ms
			JSR IF_KEYPRESS
			BCLR PTBD_PTBD5, PTBD
			JSR	DEBOUNCE_50ms

			
			BSET PTBD_PTBD4, PTBD
			JSR	DEBOUNCE_50ms
			JSR IF_KEYPRESS
			BCLR PTBD_PTBD4, PTBD
			JSR	DEBOUNCE_50ms
			LDA KEY_VALUE
			BNE	KEY_EXIT
			
			BSET PTBD_PTBD3, PTBD
			JSR	DEBOUNCE_50ms
			JSR IF_KEYPRESS
			BCLR PTBD_PTBD3, PTBD
			JSR	DEBOUNCE_50ms
			LDA KEY_VALUE
			BNE	KEY_EXIT
			
			BSET PTBD_PTBD2, PTBD
			JSR	DEBOUNCE_50ms
			JSR IF_KEYPRESS
			BCLR PTBD_PTBD2, PTBD
			JSR	DEBOUNCE_50ms
			RTS
IF_KEYPRESS:
			LDA	PTAD
			AND #%00001111 ; mask column pins
			STA COLUMN_CURRENT
			; key press detected?
			CMP #%00000000
			BNE	KEY_RESPONSE ; yes, which one?		
			; no, cont. polling keypad
			RTS
KEY_RESPONSE:
			LDA	PTBD
			AND	#%00111100 ; mask row pins
			STA	ROW_CURRENT		
			ADD	COLUMN_CURRENT	; encode two bytes into one
			STA	KEY_BYTE ; save for table comparison
			LDHX #KEY_TABLE	; index table
			PSHH
			BRA	KEY_CMP
KEY_CMP:
			; indexed whole table?
			LDA	MAX_IX
			INCA
			STA MAX_IX
			CMP	#33
			BEQ	KEY_EXIT	; yes, index out of bounds
			; no, keep searching					
			MOV	X+,MPR
			LDA	MPR
			; key found?
			CMP	KEY_BYTE
			BNE	KEY_CMP	; no, keep searching
			; yes, save for later
			MOV	X+, KEY_VALUE
			LDA	KEY_VALUE
			STA	IIC_MSG_TX
			LDA BYTES_LEFT
			DECA
			STA BYTES_LEFT
			PULH
			RTS
KEY_EXIT:
			NOP
			RTS
