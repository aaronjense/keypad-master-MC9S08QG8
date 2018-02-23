;*******************************************************************
; EE465: Microcontroller Applications
; Montana State University, Bozeman
; by Aaron Jense
;
; I2C using IICC module
; Primarily master for transmit.                                            *
;*******************************************************************
            INCLUDE 'derivative.inc'
            XDEF  _VICC, SETUP_IIC_MASTER, IIC_SEND, IIC_SLAVE_ADDR, IIC_MSG_TX
            
MY_ZEROPAGE: SECTION  SHORT         ; Insert here your data definition
	IIC_SLAVE_ADDR:	DS.B 1
	IIC_MSG_TX:		DS.B 1 
	IIC_MSG_RX:		DS.B 1
	IIC_TX_CNT:		DS.B 1
	IIC_RX_CNT:		DS.B 1
	BAUDRATE:		EQU %10111111    ; (BUSCLK / M*ICR) M=4, ICR=3840
ROM_VAR: SECTION
MyCode:     SECTION
main:
SETUP_IIC_MASTER:
			LDA #0
			STA IIC_SLAVE_ADDR
			STA IIC_MSG_RX
			BSET IICC_IICEN, IICC	; enable IIC interface
			MOV #BAUDRATE, IICF	 	; write IICF, sets IIC baud rate
			BSET IICC_IICIE, IICC   ; interrupt enabled
			RTS
IIC_SEND:
			LDHX #0
			MOV #1, IIC_TX_CNT
			LDA #0
			STA IIC_RX_CNT
			BSET IICC_TX, IICC ; set for data transfer
			BSET IICC_MST, IICC ; Send start signal
			LDA IIC_SLAVE_ADDR
			AND #%11111110 ; ensure R/W = 0
			STA	IICD	; Send Address Byte
			RTS		
_VICC:
			BSET IICS_IICIF, IICS  ; clear the interrupt
			; Master mode?	;yes
			; TX mode?			
			BRSET IICC_TX,IICC,_VICC_TX ; yes
			; no, RX
			BRA _VICC_RX
			RTI
_VICC_TX:
			BSET IICC_TX, IICC ; set for data transfer
			; Last Byte Transmitted?
			LDA IIC_TX_CNT
			CMP #0
			BEQ _VICC_STOP  ;yes, send stop
			; no
			; Received Acknowledge from Slave?
			BRSET IICS_RXAK,IICS,_VICC_STOP ; no, send stop
			; yes
			BRA	_VICC_EOC_CHECK
			RTI
_VICC_EOC_CHECK: ; End of Address Cycle Check
			; Switch to RX?
			BRCLR IICC_TX,IICC,_VICC_RX ; yes
			; no, send next byte
			BRA _VICC_TX_NEXT
			RTI
_VICC_TX_NEXT:
			DEC IIC_TX_CNT
			LDA	IIC_MSG_TX
			STA IICD
			RTI	
_VICC_SLAVE:
			; Arbritration lost?
			BRSET IICS_ARBL,IICS, _VICC_ARB_LOST ; yes
			; no
			; add later
			RTI
_VICC_ARB_LOST:
			BSET IICS_ARBL,IICS ; Acknowledge arbritration
			BRA	_VICC_STOP
			RTI		
_VICC_RX:
			BCLR IICC_TX, IICC ; switch to RX mode
			LDA	IICD ; Dummy read to initiate receiving
			RTI
_VICC_RX_NEXT:
			; Last byte to be read?
			LDA	IIC_RX_CNT
			CMP	#0
			BEQ	_VICC_READ	;yes, send stop and read
			; no, second last byte to be read?
			CMP	#1
			BEQ	_VICC_TXAK
			LDA	IICD
			STA	IIC_MSG_RX
			RTI
_VICC_STOP:
			BCLR IICC_MST, IICC ; Generate Stop signal
			RTI
_VICC_READ:
			BCLR IICC_MST, IICC ; Generate Stop signal
			LDA	IICD
			STA	IIC_MSG_RX
			RTI
_VICC_TXAK:
			BSET IICC_TXAK,IICC	; No acknowledge will be sent
			LDA	IICD
			STA	IIC_MSG_RX
			RTI
