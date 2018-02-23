;*******************************************************************
; EE465: Microcontroller Applications
; Montana State University, Bozeman
; by Aaron Jense
;
; Simple utility subroutines
;*******************************************************************
            INCLUDE 'derivative.inc'

            XDEF DEBOUNCE_50ms,BLINK

MY_ZEROPAGE: SECTION  SHORT
	DELAY: 	    		DS.B 2
ROM_VAR: SECTION
MyCode:     SECTION
main:
DEBOUNCE_50ms:
			LDHX #0
			BRA	DELAY_LOOP
DELAY_LOOP:
			AIX	#1
			CPHX #$3013
			BNE	DELAY_LOOP		
			RTS
BLINK:
			BSET 0, PTBD
			JSR DEBOUNCE_50ms
			JSR DEBOUNCE_50ms
			JSR	DEBOUNCE_50ms
			JSR	DEBOUNCE_50ms
			JSR	DEBOUNCE_50ms
			JSR DEBOUNCE_50ms
			JSR DEBOUNCE_50ms
			BCLR 0, PTBD
			RTS
