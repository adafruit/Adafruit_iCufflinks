.include "tn4def.inc"


.equ    LED = 0				; LED connected to PB0
.equ	DELAYTIME = 17		; 17 ms between PWM changes

.cseg 

.org 0x0000
	rjmp	RESET

.def	temp   		= R16	; general purpose temp
.def	delaycnt1  	= R17   ; counter for 1ms delay loop
.def	delayms  	= R28	; keeps track of how many ms left in delay

RESET:
	sbi		DDRB, LED		; LED output
	sbi		PORTB, LED    	; LED off

	; set up fast PWM output timer WGM[3:0] = 0101
	; COM0A1 = 1, COM0A0 = 0 or 1
	ldi		temp, 0xC1		;  Fast PWM (PB2 output)
	out		TCCR0A, temp
	ldi		temp, 0x81      ; fastest clock
	out		TCCR0B, temp

	; we dont use the top of the counter since its only 8 bit
	ldi		temp, 0
	out		OCR0AH, temp


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

	; delay!
	ldi		delayms, DELAYTIME			; delay ~17 ms
DELAY:
	ldi		delaycnt1, 0xFF
	DELAY1MS:   ; this loop takes about 1ms (with 1 MHz clock)
		dec		delaycnt1      ; 1 clock
		cpi		delaycnt1, 0   ; 1 clock
		brne	DELAY1MS       ; 2 clocks (on avg)
	dec		delayms
	cpi		delayms, 0
	brne	DELAY

	rjmp	LOOP


PULSETAB:
.db 255, 255, 255, 255, 255, 255, 255, 255, 252, 247, 235, 235, 230, 225, 218, 213, 208, 206, 199, 189, 187, 182, 182, 177, 175, 168, 165, 163, 158, 148, 146, 144, 144, 141, 139, 136, 134, 127, 122, 120, 117, 115, 112, 112, 110, 110, 108, 103, 96, 96, 93, 91, 88, 88, 88, 88, 84, 79, 76, 74, 74, 72, 72, 72, 72, 69, 69, 62, 60, 60, 57, 57, 57, 55, 55, 55, 55, 48, 48, 45, 45, 43, 43, 40, 40, 40, 40, 36, 36, 36, 33, 33, 31, 31, 31, 28, 28, 26, 26, 26, 26, 24, 24, 21, 21, 21, 21, 20, 19, 19, 16, 16, 16, 16, 14, 14, 14, 16, 12, 12, 12, 12, 12, 9, 9, 9, 9, 9, 9, 7, 7, 7, 7, 7, 7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 4, 4, 4, 7, 7, 7, 7, 7, 7, 9, 9, 9, 12, 12, 12, 14, 14, 16, 16, 16, 16, 21, 21, 21, 21, 24, 24, 26, 28, 28, 28, 31, 36, 33, 36, 36, 40, 40, 43, 43, 45, 48, 52, 55, 55, 55, 57, 62, 62, 64, 67, 72, 74, 79, 81, 86, 86, 86, 88, 93, 96, 98, 100, 112, 115, 117, 124, 127, 129, 129, 136, 141, 144, 148, 160, 165, 170, 175, 184, 189, 194, 199, 208, 213, 220, 237, 244, 252, 255, 255, 255, 255, 255, 255, 255, 0


