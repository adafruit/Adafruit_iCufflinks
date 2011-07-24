.include "tn4def.inc"

.equ    LED = 0				; LED connected to PB0

.cseg
.org 0x0000
	rjmp RESET
.org 0x0008
	rjmp WDT

.def	temp   		= R16	; general purpose temp

RESET:
	sbi DDRB, LED ; LED output
	sbi PORTB, LED ; LED off

	; setting all pullups on unused pins (for power savings)
	; would having them all be outputs use less power?
	ldi temp, (1<<PUEB3)|(1<<PUEB2)|(1<<PUEB1)
	out PUEB, temp

	; changing clock prescale to slow down the processing power 
	; (for power savings)
	; this affects the PWM frequency so if you go too low
	; it may look a little flickery.
	ldi		temp, 0xD8		; write signature
	out		CCP, temp
	; scale to divide by 64. So 8Mhz -> 128kHz
	ldi temp, (0<<CLKPS3)|(1<<CLKPS2)|(1<<CLKPS1)|(0<<CLKPS0) 
	out		CLKPSR, temp

	; set up fast PWM output timer WGM[3:0] = 0101
	; COM0A1 = 1, COM0A0 = 0 or 1
	ldi temp, 0xC1			; Fast PWM (PB2 output)
	out TCCR0A, temp
	ldi temp, 0x81			; fastest clock
	out TCCR0B, temp

	; we dont use the top of the counter since its only 8 bit
	ldi temp, 0
	out OCR0AH, temp

	; enable sleep mode
	ldi temp, (1<<SE) ; by default the mode is 000 Idle
	out SMCR, temp

	sei		; enable global interrupts

LOOPSTART:

	; This is start of Code in Tiny4/5/9/10 (0x4000)
	ldi ZH,	high(SINETAB*2) + 0x40 
	ldi ZL, low (SINETAB*2) ; init Z-pointer to storage bytes
LOOP:
	ld		temp, Z+ ; load next led brightness
	cpi		temp, 0			; last entry?
	brne	NORELOAD
    rjmp    LOOPSTART

NORELOAD:
	out OCR0AL, temp ; Shove the brightness into the PWM driver

	; we want to sleep 6k cycles to match the timing so sleep twice!
	ldi temp, 0xD8		; write signature
	out CCP, temp
	; set watchdog in interrupt mode and 2k cycles
	ldi temp, (0<<WDE)|(1<<WDIE)
	out WDTCSR, temp

	; reset the watchdog timer to full value and sleep until it pops an interrupt
	wdr
	sleep

	ldi temp, 0xD8		; write signature
	out CCP, temp
	; set watchdog in interrupt mode and 4k cycles
	ldi temp, (0<<WDE)|(1<<WDIE)|(1<<WDP0) 
	out WDTCSR, temp

	; reset the watchdog timer to full value and sleep until it pops an interrupt
	wdr
	sleep

	rjmp	LOOP

; this is a do nothing interrupt handler for the watchdog interrupt
WDT:
	reti

SINETAB:
.db 1, 1, 2, 3, 5, 8, 11, 15, 20, 25, 30, 36, 43, 49, 56, 64, 72, 80, 88, 97, 105, 114, 123, 132, 141, 150, 158, 167, 175, 183, 191, 199, 206, 212, 219, 225, 230, 235, 240, 244, 247, 250, 252, 253, 254, 255, 254, 253, 252, 250, 247, 244, 240, 235, 230, 225, 219, 212, 206, 199, 191, 183, 175, 167, 158, 150, 141, 132, 123, 114, 105, 97, 88, 80, 72, 64, 56, 49, 43, 36, 30, 25, 20, 15, 11, 8, 5, 3, 2, 1, 0
