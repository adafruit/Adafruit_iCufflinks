.include "tn4def.inc"


.equ LED = 0 ; LED connected to PB0
.equ DELAYTIME = 50 ; 50 ms between PWM changes

.cseg

.org 0x0000
rjmp RESET

.def temp = R16 ; general purpose temp
.def idx = R17 ; sine table indexer
.def delaycnt1 = R18 ; counter for 1ms delay loop
.def delayms = R19 ; keeps track of how many ms left in delay

RESET:
sbi DDRB, LED ; LED output
sbi PORTB, LED ; LED off

; set up fast PWM output timer WGM[3:0] = 0101
; COM0A1 = 1, COM0A0 = 0 or 1
ldi temp, 0xC1 ; Fast PWM (PB2 output)
out TCCR0A, temp
ldi temp, 0x81 ; fastest clock
out TCCR0B, temp

; we dont use the top of the counter since its only 8 bit
ldi temp, 0
out OCR0AH, temp

ldi idx, 0
LOOP:
    ldi ZH,high(SINETAB*2) + 0x40 ; This is start of Code in Tiny10 (0x4000)
    ldi ZL, low (SINETAB*2) ; init Z-pointer to storage bytes

add ZL, idx
inc idx

ld temp, Z ; load next led brightness
cpi temp, 0 ; last entry?
brne NORELOAD
ldi idx, 0 ; rewind to the beginning of the table
NORELOAD:

out OCR0AL, temp ; Shove the brightness into the PWM driver

; delay!
ldi delayms, DELAYTIME ; delay 10 ms
DELAY:
ldi delaycnt1, 0xFF
DELAY1MS: ; this loop takes about 1ms (with 1 MHz clock)
dec delaycnt1 ; 1 clock
cpi delaycnt1, 0 ; 1 clock
brne DELAY1MS ; 2 clocks (on avg)
dec delayms
cpi delayms, 0
brne DELAY

rjmp LOOP


SINETAB:
.db 1, 1, 2, 3, 5, 8, 11, 15, 20, 25, 30, 36, 43, 49, 56, 64, 72, 80, 88, 97, 105, 114, 123, 132, 141, 150, 158, 167, 175, 183, 191, 199, 206, 212, 219, 225, 230, 235, 240, 244, 247, 250, 252, 253, 254, 255, 254, 253, 252, 250, 247, 244, 240, 235, 230, 225, 219, 212, 206, 199, 191, 183, 175, 167, 158, 150, 141, 132, 123, 114, 105, 97, 88, 80, 72, 64, 56, 49, 43, 36, 30, 25, 20, 15, 11, 8, 5, 3, 2, 1, 0


