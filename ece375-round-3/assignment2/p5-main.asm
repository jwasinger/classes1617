.include "m128def.inc"				; Include definition file

.def minimum=r16
.def count=r17
.def location=r18
.def mpr=r19

.equ COUNT_MAX = 7


.dseg
AddrNums:   .db $01, $BE, $35, $EC, $48, $2D, $04, $02

.cseg
.ORG $0000
  rjmp    INIT

.ORG $0046
INIT:
  ;initialize stack
  ldi	mpr, low(RAMEND)
  out	SPL, mpr
  ldi	mpr, high(RAMEND)
  out	SPH, mpr

  rcall Min

Min:	ldi		XL, low(AddrNums)
		ldi		XH, high(AddrNums)
		ld		location, X
		ldi		count, COUNT_MAX
		mov		minimum, location

Loop:	dec		count
		inc		XL
		ld		location, X
		cp		minimum, location 
		brlo	EndLoop
		mov		minimum, location ; set a new maximum if we have found a higher number
EndLoop:
		cpi		count, 0
		brne	Loop
		ldi		XL, 0x08
		ldi		XH, 0x00
		st		X, minimum
		ret

