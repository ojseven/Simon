 	.title	"random.asm"
;*******************************************************************************
;   Pseudo-random number generator
;
;   Description:
;		Routines to set, read, and get a 16-bit pseudo-random number.
;
;		07/2011	Initial program
;		11/2011	Cosmetic updates
;		03/2013	Elimated rand6,initRand16
;
;  Built with Code Composer Essentials Version: 5.2
;*******************************************************************************

		.def	rand16				; get 16-bit random #
		.def	setrandSeed			; set random # seed
		.def	getrandSeed			; get current random # seed
		.def	MPYU				; r4 x r5 -> r6|r7
		.def	DIVU				; r4|r5 / r6 -> r5 R r4

;------------------------------------------------------------------------------
; INITIALIZATION CONSTANTS FOR RANDOM NUMBER GENERATION
;
SEED	.equ	21845				; Arbitrary seed value (65536/3)
MULT	.equ	31821				; Multiplier value (last 3 Digits are even21)
INC		.equ	13849				; 1 and 13849 have been tested

;	variables
		.bss	randSeed,2			; random seed

		.text						; Program Section
;------------------------------------------------------------------------------
; SUBROUTINE: SET RANDOM SEED
;
;	IN:		r12 = new random seed
;
setrandSeed:
		mov.w	r12,&randSeed		; set seed
		ret

;------------------------------------------------------------------------------
; SUBROUTINE: GET RANDOM SEED
;
;	OUt:	r12 = current random seed
;
getrandSeed:
		mov.w	&randSeed,r12		; return seed
		ret
		

;------------------------------------------------------------------------------
; SUBROUTINE: GENERATES NEXT RANDOM NUMBER
;
;	OUT:	r12 = 0-32767
;			random seed updated
;
rand16:
		push	r4					; save registers
		push	r5
		push	r6
		push	r7

		mov.w	&randSeed,r5			; Prepare multiplication
		mov.w	#MULT,r4			; Prepare multiplication
		call	#MPYU				; Call unsigned MPY (5.1.1)
		add.w	#INC,r7				; Add INC to low word of product
		mov.w	r7,&randSeed			; Update randSeed
		mov.w	r7,r12				; return in r12
		swpb	r12
		and.w	#0x7fff,r12			; 0-32767

		pop		r7					; restore registers
		pop		r6
		pop		r5
		pop		r4
		ret							; Random number in Rndnum


;------------------------------------------------------------------------------
; Integer Subroutines Definitions: Software Multiply
; See SLAA024 - MSP430 Family Mixed-Signal Microcontroller Application Reports
;
; UNSIGNED MULTIPLY: r4 x r5 -> r6|r7
;
MPYU:	clr.w	r7					; 0 -> LSBs RESULT
		clr.w	r6					; 0 -> MSBs RESULT

; UNSIGNED MULTIPLY AND ACCUMULATE: (r4 x r5) + r6|r7 > r6|r7
;
MACU:	push	r8
		clr.w	r8					; MSBs MULTIPLIER

L$01:	bit.w	#1,r4				; TEST ACTUAL BIT 5-4
		  jz	L$02				; IF 0: DO NOTHING
		add.w	r5,r7				; IF 1: ADD MULTIPLIER TO RESULT
		addc.w	r8,r6

L$02:	rla.w	r5					; MULTIPLIER x 2
		rlc.w	r8					;
		rrc.w	r4					; NEXT BIT TO TEST
		  jnz	L$01				; IF BIT IN CARRY: FINISHED

L$03:	pop		r8
		ret

;------------------------------------------------------------------------------
; Integer Subroutines Definitions: Software Divide
; See SLAA024 - MSP430 Family Mixed-Signal Microcontroller Application Reports
;
; UNSIGNED DIVISION SUBROUTINE 32–BIT BY 16–BIT
; UNSIGNED DIVIDE: r5 R r4 = r4|r5 / r6
; RETURN: CARRY = 0: OK CARRY = 1: QUOTIENT > 16 BITS
;
DIVU:	push	r7
		push	r8
		clr.w	r7				; clear result
		mov.w	#17,r8			; initialize loop counter

D$01:	cmp.w	r6,r4			; subtrahend < minuhend?
		  jlo	D$02			; n
		sub.w	r6,r4			; y, subtract out

D$02:	rlc.w	r7				; next bit, overflow?
		  jc	D$04			; y, result > 16 bits
		dec.w	r8				; n, decrement loop counter, done?
		  jz	D$03			; y, terminate w/o error
		rla.w	r5				; n,
		rlc.w	r4				; adjust result, enter bit in result?
		  jnc	D$01			; n
		sub.w	r6,r4			; y
		setc
		jmp		D$02

D$03:	clrc					; no error, c = 0

D$04:	mov.w	r7,r5			; return r5 = r4|r5 / r6
		pop		r8
		pop		r7
		ret						; error indication in c

		.end
