     .title  "simon.asm"
;*******************************************************************************
;  Project:  simon.asm
;  Author:   Student, Su2012
;
;  Description: A MSP430 assembly language program that plays the game of Simon.
;
;    1. Each round of the game starts by the LEDs flashing several times.
;    2. The colored LEDs (along with the associated tones) then flash one at
;       a time in a random sequence.
;    3. The push button switches are sampled and compared with the original
;       sequence of colors/tones.
;    4. The sampling the switches continues until the end of the sequence is
;       successfully reached or a mistake is made.
;    5. Some congratulatory tune is played if the sequence is correct or some
;       raspberry sound is output if a mistake is made.
;    6. If the complete sequence is successfully reproduced, the game is
;       repeated with one additional color/tone added to the sequence.
;       Otherwise, the game starts over with the default number of colors/tones.
;
;  Requirements:
;	Timer_B output (TB2) is used for hardware PWM of the transducer (buzzer).
;	Subroutines in at least one assembly and one C file are used by your program.
;	ALL subroutines must be correctly implemented using Callee-Save protocol.
;
;  Bonus:
;
;      -Port 1 interrupts are used to detect a depressed switch.
;	  -Use LCD to display round, score, highest score, and lowest score.
;	  -Turn on LCD backlight with any activity.
;	  -Turn off LCD backlight after 5 seconds of inactivity.
;
;*******************************************************************************
;   constants and equates
;
        .cdecls C,LIST,"msp430x22x4.h"
;
;*******************************************************************************
;
;                            MSP430F2274
;                  .-----------------------------.
;            SW1-->|P1.0^                    P2.0|<->LCD_DB0
;            SW2-->|P1.1^                    P2.1|<->LCD_DB1
;            SW3-->|P1.2^                    P2.2|<->LCD_DB2
;            SW4-->|P1.3^                    P2.3|<->LCD_DB3
;       ADXL_INT-->|P1.4                     P2.4|<->LCD_DB4
;        AUX INT-->|P1.5                     P2.5|<->LCD_DB5
;        SERVO_1<--|P1.6 (TA1)               P2.6|<->LCD_DB6
;        SERVO_2<--|P1.7 (TA2)               P2.7|<->LCD_DB7
;                  |                             |
;         LCD_A0<--|P3.0                     P4.0|-->LED_1 (Green)
;        i2c_SDA<->|P3.1 (UCB0SDA)     (TB1) P4.1|-->LED_2 (Orange) / SERVO_3
;        i2c_SCL<--|P3.2 (UCB0SCL)     (TB2) P4.2|-->LED_3 (Yellow) / SERVO_4
;         LCD_RW<--|P3.3                     P4.3|-->LED_4 (Red)
;   TX/LED_5 (G)<--|P3.4 (UCA0TXD)     (TB1) P4.4|-->LCD_BL
;             RX-->|P3.5 (UCA0RXD)     (TB2) P4.5|-->SPEAKER
;           RPOT-->|P3.6 (A6)          (A15) P4.6|-->LED 6 (R)
;           LPOT-->|P3.7 (A7)                P4.7|-->LCD_E
;                  '-----------------------------'
;
;******************************************************************************
;    Define some LED macros

;	REF SECTION
	.ref rand16
	.ref getrandSeed
	.ref setrandSeed

    .asg "bis.b    #0x01,&P4OUT",LED1_ON
    .asg "bic.b    #0x01,&P4OUT",LED1_OFF

    .asg "bis.b    #0x02,&P4OUT",LED2_ON
    .asg "bic.b    #0x02,&P4OUT",LED2_OFF

    .asg "bis.b    #0x04,&P4OUT",LED3_ON
    .asg "bic.b    #0x04,&P4OUT",LED3_OFF

    .asg "bis.b    #0x08,&P4OUT",LED4_ON
    .asg "bic.b    #0x08,&P4OUT",LED4_OFF

;	mov.b	&CALBC1_8MHZ,&BCSCTL1   ; Set range
;	mov.b   &CALDCO_8MHZ,&DCOCTL    ; Set DCO step + modulation
;myCLOCK .equ    1200000                ; 1.2 Mhz clock
myCLOCK .equ    8000000                 ; 1.2 Mhz clock
WDT_CTL .equ    WDT_MDLY_32             ; WD configuration (Timer, SMCLK, 32 ms)
WDT_CPI .equ    32000                   ; WDT Clocks Per Interrupt (@1 Mhz)
WDT_IPS .equ    myCLOCK/WDT_CPI         ; WDT Interrupts Per Second
STACK   .equ    0x0600                  ; top of stack

TONE    .equ    2000                    ; buzzer tone
sTone   .equ    4500              ; buzzer tone
DELAY   .equ    30                      ; delay count was 20
gsDELAY .equ    100                      ; delay count
Temp    .equ    15000
DEBOUNCE   .equ    10

;*******************************************************************************
;       RAM section
;
        .bss    WDTSecCnt,2             ; watchdog counts/second
        .bss    WDT_delay,2             ; watchdog delay counter
;        .bss    currentSeed,2
		.bss    debounce_cnt,2        ; debounce count
		.bss    buttonTest,2

;*******************************************************************************
;       ROM section
;
        .text                           ; code Section
reset:  mov.w   #STACK,SP               ; Initialize stack pointer
        call    #myInit	           ; initialize development board

;       Set Watchdog interval
        mov.w   #WDT_CTL,&WDTCTL        ; Set Watchdog interrupt interval
        mov.w   #WDT_IPS,WDTSecCnt
        mov.b   #WDTIE,&IE1             ; Enable WDT interrupt

;       enable buzzer to use Timer B PWM
 		mov.w   #1,r15
        clr.w   &TBR                    ; Timer B SMCLK, /1, up mode
        mov.w   #TBSSEL_2|ID_0|MC_1,&TBCTL
        mov.w   #OUTMOD_3,&TBCCTL2      ; output mode = set/reset
       	bis.b  #0x20,&P4DIR             ; P4.5 output (buzzer)
       	bis.b  #0x20,&P4SEL             ; select alternate output (TB2) for P4.5

;       enable interrupts
        bis.w   #GIE,SR                 ; enable interrupts
;		mov.w  #1, r15
;

 		call    #gameStart

		push    r12
		call    #getrandSeed
;		call #testSeed
		mov.w   r12, r10
		pop     r12

 		mov.w   #0,r5
		mov.w   #0, r13
 		mov.w   r5, r15
 		add.w   r13,r5
		mov.w   r14, r9

loop:	add.w   #1, r5
		mov.w   r5, r13
		mov.w   r5, r15
		mov.w   r9, r14

loop02: call #setSeed
;		call #testSeed
		call	#rand16
		add.w	r12,r14	; generate some random #
		mov.w	r14,r12
        and.w   #0x0003,r12
										;and.w 0x0003, r12
		cmp.b   #0x0000, r12
				jeq jumpin1
		cmp.b   #0x0001, r12
				jeq jumpin2
		cmp.b   #0x0002, r12
				jeq jumpin3
		cmp.b   #0x0003, r12
				jeq jumpin4

inner:  add.w   #TONE,r12
;       call    #LEDs                   ; turn on an LED
        call    #toneON                 ; turn on tone
        call    #delay                  ; delay
        dec.w	r15
          jne   loop02
        call    #toneOFF                ; turn off tone
		bic.b   #0x0f, &P4OUT
        call    #setSeed
        call    #usrInput
 ;       jmp     loop

testSeed:
 			push r12
			call #getrandSeed
		  	pop  r12
				ret

;[12:02:25 AM] bkwood89:
jumpin1: call #greenOUT
   jmp inner

jumpin2: call #orngOUT
   jmp inner

jumpin3: call #yellowOUT
   jmp inner

jumpin4: call #redOUT
   jmp inner


greenOUT: add.w  #1, r12
		 call 	 #LEDs
		 ret

orngOUT:  add.w  #1, r12
		 call 	 #LEDs
		 ret

yellowOUT: add.w #2, r12
	 	  call 	 #LEDs
		 ret

redOUT:  add.w   #5, r12
		call 	 #LEDs
		 ret

greenIN: add.w  #1, r12
;		 call 	 #LEDs
		 jmp eval

orngIN:  add.w  #1, r12
;		 call 	 #LEDs
		 jmp eval

yellowIN: add.w #2, r12
;	 	  call 	 #LEDs
		 jmp eval

redIN:  add.w   #5, r12
;		call 	 #LEDs
		 jmp eval


setSeed: push    r12
		 mov.w   r10, r12
		 call    #setrandSeed
		 pop     r12
		 	ret

usrInput:  mov.w  r5, r15
           mov.w  r9, r14

usrInner:
	        call    #getSwitch              ; get switch
;	        call    #setrandSeed
;            call    #testSeed
			call	#rand16
;	        call    #testSeed
			add.w	r12,r14	; generate some random #
			mov.w	r14,r12
	        and.w   #0x0003,r12
										;and.w 0x0003, r12
			cmp.b   #0x0000, r12
				jeq greenIN
			cmp.b   #0x0001, r12
				jeq orngIN
			cmp.b   #0x0002, r12
				jeq yellowIN
			cmp.b   #0x0003, r12
				jeq redIN

eval:
		   cmp.b   r12, r4
				jeq correct
		   jmp reset

correct:   sub.w  #1, r15
		   		jne usrInner
		   jmp loop


gameStart:
		push r12

		mov.w	#0x0008, r12            ; yellow
		call	#myLoop
		call    #delay
		call    #delay
		call    #delay
		call    #delay

		mov.w	#0x000C, r12            ; yellow
		call	#myLoop
		call    #delay
		call    #delay
		call    #delay
		call    #delay

		mov.w	#0x000E, r12            ; yellow
		call	#myLoop
		call    #delay
		call    #delay
		call    #delay
		call    #delay

		mov.w	#0x0001, r12            ; yellow
		call	#myLoop
		call    #delay
		call    #delay
		call    #delay

		mov.w	#0x0008, r12            ; yellow
		call	#myLoop
		call    #delay

		mov.w	#0x000C, r12            ; yellow
		call	#myLoop
		call    #delay

		mov.w	#0x000E, r12            ; yellow
		call	#myLoop
		call    #delay

		mov.w	#0x0001, r12            ; yellow
		call	#myLoop
		call    #delay
		call    #delay
		call    #delay

		mov.w	#0x000f, r12            ; yellow
		call	#myLoop
		call    #delay
		call    #delay
		call    #delay
		call    #delay
		call    #delay


		pop  r12

		ret

myLoop:	mov.w   #1,r15
myLoop02:
;	call	#rand16
;	add.w	r12,r14	; generate some random #
;	mov.w	r14,r12
        and.w   #0x0fff,r12
;and.w 0x0003, r12
        add.w   #TONE,r12
        call    #LEDs                   ; turn on an LED
        call    #toneON                 ; turn on tone
        call    #delay                 ; delay
        dec.w	r15
          jne   myLoop02
        call    #toneOFF                ; turn off tone
;        call    #getSwitch              ; get switch
;        jmp myLoop
		ret

;*******************************************************************************
;       turn on an LED
;
LEDs:	push	r12
        bic.b   #0x0f,&P4OUT            ; turn off LED's
        and.w	#0x0f,r12
        bis.b	r12,&P4OUT
        pop	r12
        ret

;*******************************************************************************
;       delay
;
delay:
		mov.w   #DELAY,WDT_delay        ; set WD delay counter
        bis.w   #LPM0,SR                ; goto sleep
        ret                             ; I'm awake - return

;*******************************************************************************
;       delay
;
delay2:
		mov.w   #gsDELAY,WDT_delay        ; set WD delay counter
        bis.w   #LPM0,SR                ; goto sleep
        ret                             ; I'm awake - return

;*******************************************************************************
;       get switch subroutine
;
;getSwitch:                              ; get switch subroutine
;        mov.b   &P1IN,r4                ; wait for a switch
;        and.b   #0x0f,r4
;        xor.b   #0x0f,r4                ; any switch depressed?
;          jeq   getSwitch               ; n
;        ret                             ; y, return
;-------------------------------------------------------------------------------

getSwitch:                              ; get switch subroutine
        mov.b   &P1IN,r4                ; wait for a switch
        and.b   #0x0f,r4
        xor.b   #0x0f,r4                ; any switch depressed?
          jeq   getSwitch               ; n
        xor.b r4, &P4OUT
        call    #delay
        call    #delay
        call    #delay
	    call    #delay
		call    #delay
		call    #delay
	    xor.b r4, &P4OUT
	    call    #delay
		call    #delay
		call    #delay
		call    #delay
		call    #delay
	      ret                             ; y, return












;*******************************************************************************
;    enable/disable tone
;
toneON:
        push    r12
        rra.w   r12                     ; tone / 2
        mov.w   r12,&TBCCR2             ; use TBCCR2 as 50% duty cycle
        pop     r12
        mov.w   r12,&TBCCR0             ; start clock
        ret

toneOFF:
        mov.w   #0,&TBCCR0              ; Timer B off
        ret

;*******************************************************************************
;       initialize RBX430-1 development board
;
myInit:
		mov.w	#WDTPW|WDTHOLD,&WDTCTL	; stop WDT

;	configure clocks
		mov.b	CALBC1_8MHZ,&BCSCTL1	; set range 1MHz
		mov.b	CALDCO_8MHZ,&DCOCTL	; set DCO step + modulation
		mov.w	#LFXT1S_2,&BCSCTL3	; select ACLK from VLO (no crystal)

;	configure P1
		mov.w	#0x00,&P1SEL	; select GPIO
		mov.w	#0x0f,&P1OUT	; turn off all output pins
		mov.w	#0x0f,&P1REN	; pull-up P1.0-3
		mov.w	#0xc0,&P1DIR	; P1.0-5 input, P1.6-7 output

;	configure P2
		mov.w	#0x00,&P2SEL	; GPIO
		mov.w	#0x00,&P2OUT	; turn off all output pins
		mov.w	#0x00,&P2REN	; no pull-ups
		mov.w	#0xff,&P2DIR	; P2.0-7 output

;	configure P3
		mov.w	#0x00,&P3SEL	; GPIO
		mov.w	#0x04,&P3OUT	; turn off all output pins (set SDA/SCL high)
		mov.w	#0x00,&P3REN	; no pull-ups
		mov.w	#0x1d,&P3DIR	; P3.0,2-4 output, P3.1,5-7 input

;	configure P4
		mov.w	#0x00,&P4SEL	; select GPIO
		mov.w	#0x00,&P4OUT	; turn off all output pins
		mov.w	#0x00,&P4REN	; no pull-ups
		mov.w	#0xff,&P4DIR	; P4.0-7 output
        ret


;*******************************************************************************
;       Interrupt Service Routines
;
WDT_ISR:                                ; Watchdog Timer ISR
        cmp.w   #0,WDT_delay            ; delaying?
          jeq   WDT_02                  ; n
        dec.w   WDT_delay               ; y, wake-up processor?
          jne   WDT_02                  ; n
        bic.w   #LPM0,0(SP)             ; y, clear low-power bits for reti

WDT_02:
        dec.w   WDTSecCnt               ; decrement counter, 0?
          jne   WDT_04                  ; n
        mov.w   #WDT_IPS, WDTSecCnt     ; y, re-initialize counter
        xor.b   #0x40,&P4OUT            ; toggle P4.6

WDT_04:     tst.w   debounce_cnt            ; debouncing?
            jeq   WDT_10                    ; n

; debounce switches & process

           dec.w   debounce_cnt              ; y, decrement count, done?
             jne   WDT_10                    ; n
           push    r15                       ; y
           mov.b   &P1IN,r15                 ; read switches
           and.b   #0x0f,r15
           xor.b   #0x0f,r15                 ; any switches?
             jeq   WDT_05                    ; n
;           cmp.b   #0x001, r15
;		     jeq   xor.b   #0x20,&P4OUT
			xor.b  #0x01,buttonTest

WDT_05:    pop     r15

WDT_10: reti                            ; return from interrupt



P1_ISR:    bic.b   #0x0f,&P1IFG             ; acknowledge (put hands down)
           mov.w   #DEBOUNCE,debounce_cnt   ; reset debounce count
           reti


;*******************************************************************************
;       Interrupt vector sections

        .sect   ".int10"                ; WDT vector section
        .word   WDT_ISR                 ; address of WDT ISR

		.sect   ".int02"				; Port 1 Vector
		.word   P1_ISR					; Port 1 ISR

        .sect   ".reset"                ; reset vector section
        .word   reset                   ; address of reset
        .end
