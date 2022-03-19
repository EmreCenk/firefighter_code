;Program compiled by Great Cow BASIC (0.99.01 2022-01-27 (Windows 64 bit) : Build 1073) for Microchip MPASM
;Need help? See the GCBASIC forums at http://sourceforge.net/projects/gcbasic/forums,
;check the documentation or email w_cholmondeley at users dot sourceforge dot net.

;********************************************************************************

;Set up the assembler options (Chip type, clock source, other bits and pieces)
 LIST p=16F887, r=DEC
#include <P16F887.inc>
 __CONFIG _CONFIG1, _LVP_OFF & _FCMEN_ON & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _WDTE_OFF & _INTOSCIO
 __CONFIG _CONFIG2, _WRT_OFF

;********************************************************************************

;Set aside memory locations for variables
DELAYTEMP                        EQU 112
DELAYTEMP2                       EQU 113
SYSWAITTEMPMS                    EQU 114
SYSWAITTEMPMS_H                  EQU 115

;********************************************************************************

;Vectors
	ORG	0
	pagesel	BASPROGRAMSTART
	goto	BASPROGRAMSTART
	ORG	4
	retfie

;********************************************************************************

;Start of program memory page 0
	ORG	5
BASPROGRAMSTART
;Call initialisation routines
	call	INITSYS

;Start of the main program
;----- Configuration
;Make into a comment to use the AVR chipset
;PINS FOR MOTOR 1: (change accordingly when wiring)
;#define m1port1 PortB.0
;#define m1port2 PortB.1
;PINS FOR MOTOR 2
;#define m2port1 PortB.2
;#define m2port2 PortB.3
;setting the direction of the pins
;dir m1port1 out
	banksel	TRISB
	bcf	TRISB,0
;dir m1port2 out
	bcf	TRISB,1
;dir m2port1 out
	bcf	TRISB,2
;dir m2port2 out
	bcf	TRISB,3
;MOTOR 1 COMMANDS:
;MOTOR 2 COMMANDS:
;
;Do Forever
SysDoLoop_S1
;m1_reset()
	banksel	STATUS
	call	M1_RESET
;m2_reset()
	call	M2_RESET
;Wait 1000 ms
	movlw	232
	movwf	SysWaitTempMS
	movlw	3
	movwf	SysWaitTempMS_H
	call	Delay_MS
;m1_forwards()
	call	M1_FORWARDS
;m2_forwards()
	call	M2_FORWARDS
;wait 1000 ms
	movlw	232
	movwf	SysWaitTempMS
	movlw	3
	movwf	SysWaitTempMS_H
	call	Delay_MS
;m1_backwards()
	call	M1_BACKWARDS
;m2_backwards()
	call	M2_BACKWARDS
;wait 1000 ms
	movlw	232
	movwf	SysWaitTempMS
	movlw	3
	movwf	SysWaitTempMS_H
	call	Delay_MS
;m1_forwards()
	call	M1_FORWARDS
;m2_backwards()
	call	M2_BACKWARDS
;wait 1000 ms
	movlw	232
	movwf	SysWaitTempMS
	movlw	3
	movwf	SysWaitTempMS_H
	call	Delay_MS
;m1_backwards()
	call	M1_BACKWARDS
;m2_forwards()
	call	M2_FORWARDS
;wait 1000 ms
	movlw	232
	movwf	SysWaitTempMS
	movlw	3
	movwf	SysWaitTempMS_H
	call	Delay_MS
;m1_forward
;Wait 1000 ms
;
;m1_backwards
;Wait 1000 ms
;
;m1_reset
;Wait 1000 ms
;
;
;'now testing motor 2
;m2_forward
;Wait 1000 ms
;
;m2_backwards
;Wait 1000 ms
;
;m2_reset
;Wait 1000 ms
;Loop
	goto	SysDoLoop_S1
SysDoLoop_E1
;End
	goto	BASPROGRAMEND
BASPROGRAMEND
	sleep
	goto	BASPROGRAMEND

;********************************************************************************

Delay_MS
	incf	SysWaitTempMS_H, F
DMS_START
	movlw	4
	movwf	DELAYTEMP2
DMS_OUTER
	movlw	165
	movwf	DELAYTEMP
DMS_INNER
	decfsz	DELAYTEMP, F
	goto	DMS_INNER
	decfsz	DELAYTEMP2, F
	goto	DMS_OUTER
	decfsz	SysWaitTempMS, F
	goto	DMS_START
	decfsz	SysWaitTempMS_H, F
	goto	DMS_START
	return

;********************************************************************************

;Source: system.h (156)
INITSYS
;asm showdebug This code block sets the internal oscillator to ChipMHz
;asm showdebug 'OSCCON type is 103 - This part does not have Bit HFIOFS @ ifndef Bit(HFIOFS)
;OSCCON = OSCCON OR b'01110000'
	movlw	112
	banksel	OSCCON
	iorwf	OSCCON,F
;OSCCON = OSCCON AND b'10001111'
	movlw	143
	andwf	OSCCON,F
;Address the two true tables for IRCF
;[canskip] IRCF2, IRCF1, IRCF0 = b'111'    ;111 = 8 MHz (INTOSC drives clock directly)
	bsf	OSCCON,IRCF2
	bsf	OSCCON,IRCF1
	bsf	OSCCON,IRCF0
;End of type 103 init
;asm showdebug _Complete_the_chip_setup_of_BSR,ADCs,ANSEL_and_other_key_setup_registers_or_register_bits
;Ensure all ports are set for digital I/O and, turn off A/D
;SET ADFM OFF
	bcf	ADCON1,ADFM
;Switch off A/D Var(ADCON0)
;SET ADCON0.ADON OFF
	banksel	ADCON0
	bcf	ADCON0,ADON
;ANSEL = 0
	banksel	ANSEL
	clrf	ANSEL
;ANSELH = 0
	clrf	ANSELH
;Set comparator register bits for many MCUs with register CM2CON0
;C2ON = 0
	banksel	CM2CON0
	bcf	CM2CON0,C2ON
;C1ON = 0
	bcf	CM1CON0,C1ON
;
;'Turn off all ports
;PORTA = 0
	banksel	PORTA
	clrf	PORTA
;PORTB = 0
	clrf	PORTB
;PORTC = 0
	clrf	PORTC
;PORTD = 0
	clrf	PORTD
;PORTE = 0
	clrf	PORTE
	return

;********************************************************************************

;Source: motor_code.gcb (34)
M1_BACKWARDS
;m1port1 = 0
	bcf	PORTB,0
;m1port2 = 1
	bsf	PORTB,1
	return

;********************************************************************************

;Source: motor_code.gcb (29)
M1_FORWARDS
;m1port1 = 1
	bsf	PORTB,0
;m1port2 = 0
	bcf	PORTB,1
	return

;********************************************************************************

;Source: motor_code.gcb (39)
M1_RESET
;m1port1 = 0
	bcf	PORTB,0
;m1port2 = 0
	bcf	PORTB,1
	return

;********************************************************************************

;Source: motor_code.gcb (51)
M2_BACKWARDS
;m2port1 = 0
	bcf	PORTB,2
;m2port2 = 1
	bsf	PORTB,3
	return

;********************************************************************************

;Source: motor_code.gcb (46)
M2_FORWARDS
;m2port1 = 1
	bsf	PORTB,2
;m2port2 = 0
	bcf	PORTB,3
	return

;********************************************************************************

;Source: motor_code.gcb (56)
M2_RESET
;m2port1 = 0
	bcf	PORTB,2
;m2port2 = 0
	bcf	PORTB,3
	return

;********************************************************************************

;Start of program memory page 1
	ORG	2048
;Start of program memory page 2
	ORG	4096
;Start of program memory page 3
	ORG	6144

 END
