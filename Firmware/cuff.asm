.include "tn4def.inc"

.equ    LED = 0				; LED connected to PB0

.cseg 

.org 0x0000
	rjmp	RESET
.org 0x0008
	rjmp	WDT

.def	temp   		= R16	; general purpose temp

RESET:
	sbi		DDRB, LED		; LED output
	sbi		PORTB, LED    	; LED off

	; setting all pullups on unused pins (for power savings)
	ldi		temp, (1<<PUEB3)|(1<<PUEB2)|(1<<PUEB1)		
	out		PUEB, temp

	; changing clock prescale to slow down the processing power (for power savings)
	ldi		temp, 0xD8		; write signature
	out		CCP, temp
	ldi		temp, (1<<CLKPS3)|(0<<CLKPS2)|(0<<CLKPS1)|(0<<CLKPS0)	; scale to divide by 256
	out		CLKPSR, temp

	; set up fast PWM output timer WGM[3:0] = 0101
	; COM0A1 = 1, COM0A0 = 0 or 1
	ldi		temp, 0xC1		;  Fast PWM (PB2 output)
	out		TCCR0A, temp
	ldi		temp, 0x81      ; fastest clock
	out		TCCR0B, temp

	; we dont use the top of the counter since its only 8 bit
	ldi		temp, 0
	out		OCR0AH, temp

	; setup watchdog
	ldi		temp, 0xD8		; write signature
	out		CCP, temp
	ldi		temp, (0<<WDE)|(1<<WDIE)|(1<<WDP0)	; set watchdog in interrupt mode and 4k cycles
	out		WDTCSR, temp

	; enable sleep mode
	ldi		temp, (1<<SE)	; by default the mode is 000 Idle
	out		SMCR, temp

	sei		; enable global interrupts

LOOPSTART:
   	ldi ZH, high(PULSETAB*2) + 0x40   ; This is start of Code in Tiny4 (0x4000)
   	ldi ZL, low (PULSETAB*2) 		; init Z-pointer to storage bytes 
LOOP:
	ld		temp, Z+			; load next led brightness
	cpi		temp, 0			; last entry?
	brne	NORELOAD
	; if temp == 0, means we reached the end, so reload the table index
    rjmp    LOOPSTART

NORELOAD:
	out		OCR0AL, temp	; Shove the brightness into the PWM driver

	; reset the watchdog timer to full value and sleep until it pops an interrupt
	wdr
	sleep

	rjmp	LOOP

; this is a do nothing interrupt handler for the watchdog interrupt
WDT:
	reti

PULSETAB:
.db 255, 255, 255, 255, 250, 235, 228, 216, 207, 194, 185, 180, 171, 164, 153, 145, 143, 138, 131, 121, 116, 112, 110, 106, 96, 92, 88, 88, 82, 75, 73, 72, 71, 66, 60, 57, 56, 55, 52, 47, 44, 42, 40, 38, 36, 33, 31, 30, 27, 26, 25, 23, 21, 20, 19, 16, 16, 14, 14, 12, 12, 11, 9, 9, 8, 7, 7, 6, 4, 4, 4, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 5, 7, 7, 8, 9, 12, 13, 15, 16, 18, 21, 22, 25, 28, 30, 33, 36, 40, 43, 46, 53, 55, 59, 63, 69, 76, 83, 86, 90, 97, 106, 116, 125, 129, 138, 146, 162, 172, 186, 196, 210, 228, 248, 255, 255, 255, 0
