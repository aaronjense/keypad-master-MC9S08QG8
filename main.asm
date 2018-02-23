;*******************************************************************
; EE465: Microcontroller Applications
; Montana State University, Bozeman
; by Aaron Jense
;
; Master device communicates keypress to LED and LCD HCS08 slaves.                                          *
;*******************************************************************
            INCLUDE 'derivative.inc'
            XDEF _Startup, main, BYTES_LEFT
            XREF __SEG_END_SSTACK
            XREF POLL_KEYPAD
            XREF DEBOUNCE_50ms, DELAY_LOOP, BLINK
            XREF _VICC, SETUP_IIC_MASTER, IIC_SEND, IIC_SLAVE_ADDR, IIC_MSG_TX
MY_ZEROPAGE: SECTION  SHORT
	BYTES_LEFT:		DS.B 1
ROM_VAR: SECTION
	SLAVE_LED:		DC.B 'B'
MyCode:     SECTION
main:
_Startup:            
			LDHX #__SEG_END_SSTACK ; initialize the stack pointer
            TXS
			CLI ; enable interrupts
			JSR SETUP_SOPT1
			JSR SETUP_IO
			JSR SETUP_IIC_MASTER
			LDA #0
			STA IIC_MSG_TX
			BRA mainLoop
mainLoop:
			; keep track of max bytes to send
			LDA #1
			STA BYTES_LEFT
			BRA	IS_MSG_FULL
IS_MSG_FULL:			
			LDA	BYTES_LEFT
			CMP #0
			BNE	GET_MSG_RDY ; no
			; yes, send keypress
			BRA SEND_MSG
GET_MSG_RDY:
			JSR POLL_KEYPAD
			BRA	IS_MSG_FULL
SEND_MSG:
			; Send to LED slave?
			LDA	SLAVE_LED ;yes
			STA	IIC_SLAVE_ADDR
			JSR	IIC_SEND
			BRA	mainLoop	
SETUP_SOPT1:
			LDA SOPT1 ; disable watchdog
			AND #%01111111
			STA SOPT1		
			RTS
SETUP_IO:
			LDA	#%00111111
			STA PTBDD
			LDA #%00000000
			STA PTADD
			; change IIC pins to PTB6 AND PTB7
			LDA	SOPT2
			ORA	#%00000010
			STA	SOPT2
			RTS
