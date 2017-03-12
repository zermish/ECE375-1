;***********************************************************
;*
;*	Lab 8 TX
;*
;*	Enter the description of the program here
;*
;*	This is the TRANSMIT skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def 	mpr2 = r17
.def	waitcnt = r18			; Wait Loop Counter 
.def	ilcnt = r19				; Inner Loop Counter 
.def	olcnt = r20				; Outer Loop Counter 

.equ	WTime = 100				; Time to wait in wait loop
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit
; Use these action codes between the remote and robot
; MSB = 1 thus:
.equ 	BotAddress = 0b10001001
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forward Action Code
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backward Action Code
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Action Code
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Action Code
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Action Code
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi 	mpr, high(RAMEND)
	out 	SPH, mpr
	ldi 	mpr, low(RAMEND)
	out 	SPL, mpr
	;I/O Ports
	ldi		mpr, $FF		;Set Port B Data Direction Regisiter
	out		DDRB, mpr
	ldi		mpr, $00		;Initialize Port B Data Register
	out		PORTB, mpr

	ldi		mpr, $00		;Set Port D Data Direction Register
	out		DDRD, mpr
	ldi		mpr, $FF		;Initialize Port D Data Register
	out		PORTD, mpr
	;USART1
		ldi 	mpr, (1<<U2X1)		;Set double data rate
		sts 	UCSR1A, mpr
		;Set baudrate at 2400bps
		ldi 	mpr, high(832) 	; Load high byte of 0x0340 
		sts 	UBRR1H, mpr 	; UBRR0H in extended I/O space 
		ldi 	mpr, low(832) 	; Load low byte of 0x0340 
		sts 	UBRR1L, mpr 	

		;Enable receiver and enable receive interrupts
		ldi 	mpr, (1<<TXEN1) 
		sts 	UCSR1B, mpr 		

		;Set frame format: 8 data bits, 2 stop bits
		ldi 	mpr, (1<<UCSZ10)|(1<<UCSZ11)|(1<<USBS1)|(1<<UPM01) 
		sts 	UCSR1C, mpr 		; UCSR0C in extended I/O space

	
	;External Interrupts
		;Set the External Interrupt Mask
		ldi		mpr, (1<<INT0) | (1<<INT1)
		out		EIMSK, mpr
		;Set the Interrupt Sense Control to falling edge detection
		ldi		mpr, (1<<ISC01) | (0<<ISC00) | (1<<ISC11) | (0<<ISC10)
		sts		EICRA, mpr		;Use sts, EICRA in extended I/O space
		
		sei
	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		in    mpr, PIND
		
		sbrs  mpr, 0
		rjmp  TRANSMIT_R
		
		sbrs  mpr, 1		
		rjmp  TRANSMIT_L
		
		sbrs  mpr, 2		
		rjmp  TRANSMIT_FWD
		
		sbrs  mpr, 3		
		rjmp  TRANSMIT_BCK
		
		
		jmp  MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

waitSent:
		lds 	mpr, UCSR1A
		sbrs 	mpr, TXC1
		rjmp 	waitSent
		ret

TRANSMIT_FWD:
		ldi 	mpr, BotAddress
		sts 	UDR1, mpr
		
TRANSMIT_FWD_LOOP1:
		lds 	mpr, UCSR1A
		sbrs 	mpr, TXC1
		rjmp 	TRANSMIT_FWD_LOOP1
		
		ldi 	mpr, MovFwd
		sts 	UDR1, mpr
		out 	PORTB, mpr
TRANSMIT_FWD_LOOP2:
		lds 	mpr, UCSR1A
		sbrs 	mpr, TXC1
		rjmp 	TRANSMIT_FWD_LOOP2
		
		rjmp 	MAIN

;************************************************************

TRANSMIT_BCK:
		ldi 	mpr, BotAddress
		sts 	UDR1, mpr
		
TRANSMIT_BCK_LOOP1:
		lds 	mpr, UCSR1A
		sbrs 	mpr, TXC1
		rjmp 	TRANSMIT_BCK_LOOP1
		
		ldi 	mpr, MovBck
		sts 	UDR1, mpr
		out 	PORTB, mpr
TRANSMIT_BCK_LOOP2:
		lds 	mpr, UCSR1A
		sbrs 	mpr, TXC1
		rjmp 	TRANSMIT_BCK_LOOP2
		
		rjmp 	MAIN

;************************************************************

TRANSMIT_R:
		ldi 	mpr, BotAddress
		sts 	UDR1, mpr
TRANSMIT_R_LOOP1:
		lds 	mpr, UCSR1A
		sbrs 	mpr, TXC1
		rjmp 	TRANSMIT_R_LOOP1
		
		ldi 	mpr, TurnR
		sts 	UDR1, mpr
		out 	PORTB, mpr
TRANSMIT_R_LOOP2:
		lds 	mpr, UCSR1A
		sbrs 	mpr, TXC1
		rjmp 	TRANSMIT_R_LOOP2
		
		rjmp 	MAIN

;************************************************************

TRANSMIT_L:
		ldi 	mpr, BotAddress
		sts 	UDR1, mpr
TRANSMIT_L_LOOP1:
		lds 	mpr, UCSR1A
		sbrs 	mpr, TXC1
		rjmp 	TRANSMIT_L_LOOP1
		
		ldi 	mpr, TurnL
		sts 	UDR1, mpr
		out 	PORTB, mpr
TRANSMIT_L_LOOP2:
		lds 	mpr, UCSR1A
		sbrs 	mpr, TXC1
		rjmp 	TRANSMIT_L_LOOP2
		
		rjmp 	MAIN

;************************************************************

