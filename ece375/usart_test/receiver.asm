;***********************************************************
;*
;*  robot.asm
;*
;*  This is the RECEIVE file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*   Author: Enter your name
;*     Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"      ; Include definition file

;***********************************************************
;*  Internal Register Definitions and Constants
;***********************************************************
.def  mpr = r16       ; Multi-Purpose Register
.def  receiveState = r17 ;register to hold state for receive
.def  mpr2 = r18

;registers used by blocking wait routine
.def waitcnt = r19
.def ilcnt = r20
.def olcnt = r21

.equ wait_time = 100

.equ STATE_ADDR_RECEIVED = 1
.equ STATE_NO_ADDR = 2

.equ  WskrR = 0       ; Right Whisker Input Bit
.equ  WskrL = 1       ; Left Whisker Input Bit
.equ  EngEnR = 4        ; Right Engine Enable Bit
.equ REngineEn = EngEnR
.equ  EngEnL = 7        ; Left Engine Enable Bit
.equ LEngineEn = EngEnL
.equ  EngDirR = 5       ; Right Engine Direction Bit
.equ REngineDir = EngDirR
.equ  EngDirL = 6       ; Left Engine Direction Bit
.equ LEngineDir = EngDirL

.equ MoveForwardFlags = (1<<EngEnL | 1<<EngEnR | 1<<EngDirR | 1<<EngDirL)
.equ TurnRightFlags = (0<<EngEnL | 0<<EngEnR | 0<<EngDirR | 1<<EngDirL)
.equ TurnLeftFlags = (0<<EngEnL | 0<<EngEnR | 1<<EngDirR | 0<<EngDirL)
.equ HaltFlags = (1<<EngEnL | 1<<EngEnR)
.equ MoveBackwardsFlags = (0<<EngEnL | 0<<EngEnR | 0<<EngDirR | 0<<EngDirL)

; DDRD is all zero because PORTD is used for input
; If we want to do output, we'll want to set PD3 to 1.
.equ PortDDir   = 0
; Activate pull-up resistors for the whisker pins
.equ PortDPulls = (1 << WskrR) | (1 << WskrL)
; Set DDRB to allow output on the engine pins
.equ PortBDir   = (1 << LEngineEn) | (1 << LEngineDir) | (1 << REngineDir) | (1 << REngineEn)

;; ## Interrupt Macros ##
;; These values are used to enable the necessary 
;; interrupts.
.equ extIntEnable   = (1<<INT1)|(1<<INT0)
;; This value is put into EICRA to enable INT0 and INT1 to
;; trigger on a rising edge.
.equ extIntControlA = (1<<ISC00)|(1<<ISC01)|(1<<ISC10)|(1<<ISC11)
.equ extIntControlB = 0

.equ  BotAddress = 0b00100100

.equ WTime = 100

;command codes
.equ  MoveForwardCode = 0b10110000
.equ  MoveBackCode =  0b10000000
.equ  TurnRightCode = 0b10100000
.equ  TurnLeftCode = 0b10010000 
.equ  HaltCode =  0b11001000

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

; Macro:  LPI Rr, k
; Desc:   Load direct from program memory.
; Clobbers: Z
; Operands: 0 <= r <= 29    register
;             - result undefined for r=30,31
;           0 <= k <= 65535 memory address
.macro LPI
  ldi ZH, high(@1<<1)
  ldi ZL, low(@1<<1)
  lpm @0, Z
.endmacro

;***********************************************************
;*  Start of Code Segment
;***********************************************************
.cseg             ; Beginning of code segment

;***********************************************************
;*  Interrupt Vectors
;***********************************************************
.org  $0000         ; Beginning of IVs
    rjmp  INIT      ; Reset interrupt

;- USART receive
.org $003C
  rcall UsartReceiveInterrupt
  reti

.org  $0046         ; End of Interrupt Vectors


;***********************************************************
;*  Program Initialization
;***********************************************************
INIT:
  ;Stack Pointer
  outi SPH, high(RAMEND)
  outi SPL, low(RAMEND)

  ;I/O Ports
  ;set PORTB (output) - engine control
  ; PORTB (output) - engine control
  outi DDRB, PortBDir

  ; PORTD (input) - sensors for BumpBot
  ;outi DDRD, PortDDir     ; enable input
  ;outi PORTD, PortDPulls  ; activate pull-up resistors


  ;USART1 ---------------------------------------------------
  ;Set baudrate at 2400bps
  ldi mpr, high(832)
  sts UBRR1H, mpr
  ldi mpr, low(832)
  sts UBRR1L, mpr

  ;Enable receiver and enable receive interrupts
  ldi mpr, (1<<RXEN1 | 1<<RXCIE1)
  sts UCSR1B, mpr
  
  ;Set frame format: 8 data bits, 2 stop bits
  ldi mpr, (0<<UMSEL0 | 1<<USBS0 | 1 <<UCSZ01)
  sts UCSR1C, mpr

  ;External Interrupts -------------------------------------
    ; configure when the external interrupts will be triggered
  sti EICRA, extIntControlA
  sti EICRB, extIntControlB

  ; enable the interrupts
  outi EIMSK, ExtIntEnable  ; enable external interrupts

  ;Other
  sei

;***********************************************************
;*  Main Program
;***********************************************************
MAIN:
  ;TODO: ???
	ldi mpr, (1 << EngDirR) | 1<<(EngDirL)
	out PORTB, mpr
    rjmp  MAIN

;***********************************************************
;*  Functions and Subroutines
;***********************************************************
UsartReceiveInterrupt:
	rcall HitRight
	ret

HitRight:
  ;save program state
  push mpr
  push waitcnt
  in mpr, SREG  ; push status register
  push mpr
  in mpr, PORTB ; push PORTB
  push mpr

  ;move backwards 1 sec
  ldi mpr, MoveBackwardsFlags
  out PORTB, mpr
  ldi waitcnt, WTime
  rcall Wait

  ;turn left 1 sec
  ldi mpr, TurnLeftFlags
  out PORTB, mpr
  ldi waitcnt, wait_time
  rcall Wait

  ;restore program state
  ;pop PORTB to continue previous action
  pop mpr
  out PORTB, mpr
  pop mpr
  out SREG, mpr
  pop waitcnt
  pop mpr

  ret

;******************
; wait subroutine
;******************
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
;***********************************************************
;*  Stored Program Data
;***********************************************************

;***********************************************************
;*  Additional Program Includes
;***********************************************************

