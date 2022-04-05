;Program compiled by Great Cow BASIC (0.98.06 2019-06-12 (Windows 32 bit))
;Need help? See the GCBASIC forums at http://sourceforge.net/projects/gcbasic/forums,
;check the documentation or email w_cholmondeley at users dot sourceforge dot net.

;********************************************************************************

;Set up the assembler options (Chip type, clock source, other bits and pieces)
 LIST p=16F887, r=DEC
#include <P16F887.inc>
 __CONFIG _CONFIG1, _LVP_OFF & _CP_OFF & _MCLRE_OFF & _WDTE_OFF & _INTOSCIO

;********************************************************************************

;Set aside memory locations for variables
DELAYTEMP	EQU	112
DELAYTEMP2	EQU	113
SYSWAITTEMPMS	EQU	114
SYSWAITTEMPMS_H	EQU	115
TIME1	EQU	32
TIME1_H	EQU	33

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
;Automatic pin direction setting
	banksel	TRISB
	bcf	TRISB,3

;Start of the main program
;#define m1port1 PortB.0
;#define m1port2 PortB.1
;#define m2port1 PortB.2
;#define m2port2 PortB.3
;dir m1port1 out
	bcf	TRISB,0
;dir m1port2 out
	bcf	TRISB,1
;dir m2port1 out
	bcf	TRISB,2
;dir m2port1 out
	bcf	TRISB,2
;#define led_port PortB.5
;#define line_port PortB.4
;dir line_port in
	bsf	TRISB,4
;dir led_port out
	bcf	TRISB,5
;do forever
SysDoLoop_S1
;if line_port then
	banksel	PORTB
	btfss	PORTB,4
	goto	ELSE1_1
;bot_backwards(0)
	clrf	TIME1
	clrf	TIME1_H
	call	BOT_BACKWARDS
;set led_port off
	bcf	PORTB,5
;else
	goto	ENDIF1
ELSE1_1
;bot_forward(0)
	clrf	TIME1
	clrf	TIME1_H
	call	BOT_FORWARD
;set led_port on
	bsf	PORTB,5
;end if
ENDIF1
;loop
	goto	SysDoLoop_S1
SysDoLoop_E1
BASPROGRAMEND
	sleep
	goto	BASPROGRAMEND

;********************************************************************************

BOT_BACKWARDS
;m1_backwards
	call	M1_BACKWARDS
;m2_backwards
	call	M2_BACKWARDS
;Wait time1 ms
	movf	TIME1,W
	movwf	SysWaitTempMS
	movf	TIME1_H,W
	movwf	SysWaitTempMS_H
	goto	Delay_MS

;********************************************************************************

BOT_FORWARD
;m1_forward
	call	M1_FORWARD
;m2_forward
	call	M2_FORWARD
;Wait time1 ms
	movf	TIME1,W
	movwf	SysWaitTempMS
	movf	TIME1_H,W
	movwf	SysWaitTempMS_H
	goto	Delay_MS

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

INITSYS
;asm showdebug 'OSCCON type is 103 - This part does not have Bit HFIOFS @ ifndef Bit(HFIOFS)
;
;added for 18F(L)K20 -WMR
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
;Ensure all ports are set for digital I/O and, turn off A/D
;SET ADFM OFF
	bcf	ADCON1,ADFM
;Switch off A/D Var(ADCON0)
;SET ADCON0.ADON OFF
	banksel	ADCON0
	bcf	ADCON0,ADON
;Commence clearing any ANSEL variants in the part
;ANSEL = 0
	banksel	ANSEL
	clrf	ANSEL
;ANSELH = 0
	clrf	ANSELH
;End clearing any ANSEL variants in the part
;Set comparator register bits for many MCUs with register CM2CON0
;C2ON = 0
	banksel	CM2CON0
	bcf	CM2CON0,C2ON
;C1ON = 0
	bcf	CM1CON0,C1ON
;Turn off all ports
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

M1_BACKWARDS
;m1port1 = 0
	bcf	PORTB,0
;m1port2 = 1
	bsf	PORTB,1
	return

;********************************************************************************

M1_FORWARD
;m1port1 = 1
	bsf	PORTB,0
;m1port2 = 0
	bcf	PORTB,1
	return

;********************************************************************************

M2_BACKWARDS
;m2port1 = 0
	bcf	PORTB,2
;m2port2 = 1
	bsf	PORTB,3
	return

;********************************************************************************

M2_FORWARD
;m2port1 = 1
	bsf	PORTB,2
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
