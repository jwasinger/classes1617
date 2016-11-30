    ;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the TRANSMIT skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Zane Salvaatore, Jared Wasinger
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register

.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit
; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forward Action Code
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backward Action Code
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Action Code
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Action Code
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Action Code

;---------------------------------------------------------
; Constant Macro Definitions
;---------------------------------------------------------
;; ## Port Bit Macros ##
;; These macros define the specific bits used on PORTD for
;; input and PORTB for output. They should only be used in
;; bit-shifting operations, as illustrated by the section
;; "TekBot Movement Macros".

; input port definitions - used on PORTD
.equ fullStopBit = 0
.equ decSpeedBit = 1
.equ incSpeedBit = 2
.equ maxSpeedBit = 3

; output port definitions - used on PORTB
.equ LEngineEn  = 7
.equ LEngineDir = 6
.equ REngineDir = 5
.equ REngineEn  = 4

; DDRD is all zero because PORTD is used for input
.equ PortDDir   = 0
; Activate pull-up resistors for the whisker pins
.equ PortDPulls = 0b11111111
; Set DDRB to allow output on all pins
.equ PortBDir   = $FF

.equ maxSpeed = 15
.equ minSpeed = 0

;; The address used to identify the remote to the bot.
.equ botAddress = 0b00100100


;---------------------------------------------------------
; Register Macro Definitions
;---------------------------------------------------------
.equ waitcnt = r19
.equ usart1Out = r18

; CONSTANTS

.equ wait_time = 100

;---------------------------------------------------------
; Programmatic Macro Definitions
;---------------------------------------------------------

; Macro:  OUTI A, K
; Desc:   Output an 8-bit immediate directly to an I/O 
;      register.
; Clobbers: mpr
; Cycles:  2
; Operands: 0 <= A <= 63  I/O register
;      0 <= K <= 255 immediate
; This macro simplifies the procedure of writing an
; immediate value to the I/O register space by condensing
; it into a single macro call.
.macro OUTI
  ldi mpr, @1
  out @0, mpr
.endmacro

; Macro:  OUTIW AH, AL, K
; Desc:   Output a 16-bit immediate directly to a pair 
;      of I/O registers.
; Clobbers: mpr
; Cycles:  4
; Operands: 0 <= AH <= 63  I/O register
;      0 <= AL <= 63  I/O register
;      0 <= K <= 65535 immediate
; This macro is like OUTI, but it takes two I/O registers
; and outputs the high and low bytes of K to the registers,
; putting the high byte into AH and the low byte into AL.

.macro OUTIW
  outi @0, high(@2)
  outi @1, low(@2)
.endmacro

; Macro:  STI k, K
; Desc:   Store an immediate direct to data space.
; Clobbers: mpr
; Operands: 0 <= k <= 65535 SRAM address
;      0 <= K <= 255  immediate
.macro STI
  ldi mpr, @1
  sts @0, mpr
.endmacro

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
  outiw SPH, SPL, RAMEND

	;I/O Ports
  ;; Set up PORTD for remote control input.
  outi DDRD, PortDDir
  outi PORTD, PortDPulls

  ; set up portb to show output
  outi DDRB, PortBDir
  outi PORTB, $00

	;USART1
	;ldi mpr, (1<<U2X1)  ; double data rate
  ;sts UCSR1A, mpr
  ;Set baudrate at 2400bps
  ldi mpr, high(832)
  sts UBRR1H, mpr
  ldi mpr, low(832)
  sts UBRR1L, mpr

	;Enable transmitter and Set frame format: 8 data bits, 2 stop bits
  ldi mpr, (1<<USBS1 | 1<<UCSZ11 | 1<<UCSZ10)
  sts UCSR1C, mpr
  ldi mpr, (1<<TXEN1)
  sts UCSR1B, mpr
	clr lastCmd
  sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
  ;; TODO: Implement MAIN as a busy-wait loop that polls for
  ;; button input and carries out the corresponding action.

  ; send the bot ID
  ldi usart1Out, botAddress
  call USART1_Transmit
	
  ; send the action code
  mov usart1Out, cmd
  out PORTB, lastCmd
  call USART1_Transmit

	call Wait

	rjmp	MAIN  ; repeat

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

Wait:
  push waitcnt
  push ilcnt
  push olcnt

Loop:
  ldi olcnt, 224
OLoop: 
  ldi ilcnt, 237
ILoop: 
  dec ilcnt
  brne ILoop
  dec  olcnt
  brne OLoop
  dec waitcnt
  brne Loop
  
  pop olcnt
  pop ilcnt
  pop waitcnt
  ret

; Subroutine: USART1_Transmit
; Wait until the USART1 data buffer is clear, then send the
; value in usart1Out.
USART1_Transmit:
  lds mpr, UCSR1A
  sbrs mpr, UDRE1
  rjmp USART1_Transmit

  sts UDR1, usart1Out
  ret

/*WaitForTransmit:
  push mpr
  
  ; Loop until the transmit complete bit is set in the
  ; USART status register.
  WaitForTransmit_Loop:
    lds mpr, UCSR1A
    sbrs mpr, TXC1  ; when the bit is set, jump out of the loop
      rjmp WaitForTransmit_Loop
  
  pop mpr
  ret*/

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
