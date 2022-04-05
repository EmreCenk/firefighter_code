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
LCDBYTE	EQU	32
LCDCOLUMN	EQU	33
LCDLINE	EQU	34
LCDREADY	EQU	35
LCD_STATE	EQU	36
PRINTLEN	EQU	37
STRINGPOINTER	EQU	38
SYSBYTETEMPA	EQU	117
SYSBYTETEMPB	EQU	121
SYSBYTETEMPX	EQU	112
SYSCALCTEMPA	EQU	117
SYSLCDTEMP	EQU	39
SYSPRINTDATAHANDLER	EQU	40
SYSPRINTDATAHANDLER_H	EQU	41
SYSPRINTTEMP	EQU	42
SYSREPEATTEMP1	EQU	43
SYSSTRINGA	EQU	119
SYSSTRINGA_H	EQU	120
SYSSTRINGB	EQU	114
SYSSTRINGB_H	EQU	115
SYSSTRINGLENGTH	EQU	118
SYSSTRINGPARAM1	EQU	477
SYSTEMP1	EQU	44
SYSWAITTEMP10US	EQU	117
SYSWAITTEMPMS	EQU	114
SYSWAITTEMPMS_H	EQU	115
SYSWAITTEMPUS	EQU	117
SYSWAITTEMPUS_H	EQU	118

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
	call	INITLCD

;Start of the main program
;#define LCD_IO 4
;#define LCD_Speed OPTIMAL 'defines the characters per second on the LCD
;#define LCD_RW PortD.1
;#define LCD_RS PortD.0
;#define LCD_Enable PortD.2
;#define LCD_DB7 PortD.7
;#define LCD_DB6 PortD.6
;#define LCD_DB5 PortD.5
;#define LCD_DB4 PortD.4
;#define led_port PortB.5
;dir led_port out
	banksel	TRISB
	bcf	TRISB,5
;Do Forever
SysDoLoop_S1
;set led_port on
	banksel	PORTB
	bsf	PORTB,5
;urmom()
	call	URMOM
;set led_port off
	bcf	PORTB,5
;loop
	goto	SysDoLoop_S1
SysDoLoop_E1
;End
	goto	BASPROGRAMEND
BASPROGRAMEND
	sleep
	goto	BASPROGRAMEND

;********************************************************************************

CLS
;SET LCD_RS OFF
	bcf	PORTD,0
;Clear screen
;LCDWriteByte (0b00000001)
	movlw	1
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;Wait 4 ms
	movlw	4
	movwf	SysWaitTempMS
	clrf	SysWaitTempMS_H
	call	Delay_MS
;Move to start of visible DDRAM
;LCDWriteByte(0x80)
	movlw	128
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;Wait 12 10us
	movlw	12
	movwf	SysWaitTemp10US
	goto	Delay_10US

;********************************************************************************

Delay_10US
D10US_START
	movlw	5
	movwf	DELAYTEMP
DelayUS0
	decfsz	DELAYTEMP,F
	goto	DelayUS0
	nop
	decfsz	SysWaitTemp10US, F
	goto	D10US_START
	return

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

INITLCD
;Initialization routines based upon code examples in HD44780 datasheet
;Configure RS,Enable & RW pin directions
;DIR LCD_RS OUT
	banksel	TRISD
	bcf	TRISD,0
;DIR LCD_Enable OUT
	bcf	TRISD,2
;DIR LCD_RW OUT
	bcf	TRISD,1
;wait 10 ms
	movlw	10
	movwf	SysWaitTempMS
	clrf	SysWaitTempMS_H
	banksel	STATUS
	call	Delay_MS
;Wait until LCDReady
SysWaitLoop1
	call	FN_LCDREADY
	movf	LCDREADY,F
	btfsc	STATUS,Z
	goto	SysWaitLoop1
;SET LCD_RS OFF
	bcf	PORTD,0
;4-bit initialization routine
;Set pins to output
;DIR LCD_DB4 OUT
	banksel	TRISD
	bcf	TRISD,4
;DIR LCD_DB5 OUT
	bcf	TRISD,5
;DIR LCD_DB6 OUT
	bcf	TRISD,6
;DIR LCD_DB7 OUT
	bcf	TRISD,7
;set LCD_RW OFF
	banksel	PORTD
	bcf	PORTD,1
;wait 15 ms
	movlw	15
	movwf	SysWaitTempMS
	clrf	SysWaitTempMS_H
	call	Delay_MS
;Wakeup 0x30
;set LCD_DB4 ON
	bsf	PORTD,4
;set LCD_DB5 ON
	bsf	PORTD,5
;set LCD_DB6 OFF
	bcf	PORTD,6
;set LCD_DB7 OFF
	bcf	PORTD,7
;wait 2 us
	goto	$+1
	goto	$+1
;PULSEOUT LCD_Enable, 2 us
;Set Pin On
	bsf	PORTD,2
;Wait Time
	goto	$+1
	goto	$+1
;Set Pin Off
	bcf	PORTD,2
;wait 5 ms
	movlw	5
	movwf	SysWaitTempMS
	clrf	SysWaitTempMS_H
	call	Delay_MS
;Repeat 3   'three more times
	movlw	3
	movwf	SysRepeatTemp1
SysRepeatLoop1
;PULSEOUT LCD_Enable, 2 us
;Set Pin On
	bsf	PORTD,2
;Wait Time
	goto	$+1
	goto	$+1
;Set Pin Off
	bcf	PORTD,2
;Wait 200 us
	movlw	133
	movwf	DELAYTEMP
DelayUS1
	decfsz	DELAYTEMP,F
	goto	DelayUS1
;end repeat
	decfsz	SysRepeatTemp1,F
	goto	SysRepeatLoop1
SysRepeatLoopEnd1
;Wait 5 ms
	movlw	5
	movwf	SysWaitTempMS
	clrf	SysWaitTempMS_H
	call	Delay_MS
;Set 4 bit mode    (0x20)
;set LCD_DB4 OFF
	bcf	PORTD,4
;set LCD_DB5 ON
	bsf	PORTD,5
;set LCD_DB6 OFF
	bcf	PORTD,6
;set LCD_DB7 OFF
	bcf	PORTD,7
;wait 2 us
	goto	$+1
	goto	$+1
;PULSEOUT LCD_Enable, 2 us
;Set Pin On
	bsf	PORTD,2
;Wait Time
	goto	$+1
	goto	$+1
;Set Pin Off
	bcf	PORTD,2
;Wait 50 us
	movlw	33
	movwf	DELAYTEMP
DelayUS2
	decfsz	DELAYTEMP,F
	goto	DelayUS2
;init 4 bit mode
;LCDWriteByte 0x28    '(b'011000000') 0x28  set 2 line mode
	movlw	40
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;LCDWriteByte 0x06    '(b'00000110')  'Set Cursor movement
	movlw	6
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;LCDWriteByte 0x0C    '(b'00001100')  'Turn off cursor
	movlw	12
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;CLS  'Clear the display
	call	CLS
;LCD_State = 12
	movlw	12
	movwf	LCD_STATE
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

LCDNORMALWRITEBYTE
;wait until LCDReady
SysWaitLoop2
	call	FN_LCDREADY
	movf	LCDREADY,F
	btfsc	STATUS,Z
	goto	SysWaitLoop2
;set LCD_RW OFF 'Write mode
	bcf	PORTD,1
;Set pins to output
;DIR LCD_DB4 OUT
	banksel	TRISD
	bcf	TRISD,4
;DIR LCD_DB5 OUT
	bcf	TRISD,5
;DIR LCD_DB6 OUT
	bcf	TRISD,6
;DIR LCD_DB7 OUT
	bcf	TRISD,7
;Write upper nibble to output pins
;set LCD_DB4 OFF
	banksel	PORTD
	bcf	PORTD,4
;set LCD_DB5 OFF
	bcf	PORTD,5
;set LCD_DB6 OFF
	bcf	PORTD,6
;set LCD_DB7 OFF
	bcf	PORTD,7
;if LCDByte.7 ON THEN SET LCD_DB7 ON
	btfsc	LCDBYTE,7
	bsf	PORTD,7
;if LCDByte.6 ON THEN SET LCD_DB6 ON
	btfsc	LCDBYTE,6
	bsf	PORTD,6
;if LCDByte.5 ON THEN SET LCD_DB5 ON
	btfsc	LCDBYTE,5
	bsf	PORTD,5
;if LCDByte.4 ON THEN SET LCD_DB4 ON
	btfsc	LCDBYTE,4
	bsf	PORTD,4
;wait 1 us
	goto	$+1
;pulseout LCD_enable, 2 us
;Set Pin On
	bsf	PORTD,2
;Wait Time
	goto	$+1
	goto	$+1
;Set Pin Off
	bcf	PORTD,2
;Wait 2 us
	goto	$+1
	goto	$+1
;All data pins low
;set LCD_DB4 OFF
	bcf	PORTD,4
;set LCD_DB5 OFF
	bcf	PORTD,5
;set LCD_DB6 OFF
	bcf	PORTD,6
;set LCD_DB7 OFF
	bcf	PORTD,7
;Write lower nibble to output pins
;if LCDByte.3 ON THEN SET LCD_DB7 ON
	btfsc	LCDBYTE,3
	bsf	PORTD,7
;if LCDByte.2 ON THEN SET LCD_DB6 ON
	btfsc	LCDBYTE,2
	bsf	PORTD,6
;if LCDByte.1 ON THEN SET LCD_DB5 ON
	btfsc	LCDBYTE,1
	bsf	PORTD,5
;if LCDByte.0 ON THEN SET LCD_DB4 ON
	btfsc	LCDBYTE,0
	bsf	PORTD,4
;wait 1 us
	goto	$+1
;pulseout LCD_enable, 2 us
;Set Pin On
	bsf	PORTD,2
;Wait Time
	goto	$+1
	goto	$+1
;Set Pin Off
	bcf	PORTD,2
;wait 2 us
	goto	$+1
	goto	$+1
;Set data pins low again
;SET LCD_DB7 OFF
	bcf	PORTD,7
;SET LCD_DB6 OFF
	bcf	PORTD,6
;SET LCD_DB5 OFF
	bcf	PORTD,5
;SET LCD_DB4 OFF
	bcf	PORTD,4
;character delay settings
;If Register Select is low.  14.02.19
;IF LCD_RS = 0 then
	btfsc	PORTD,0
	goto	ENDIF16
;IF LCDByte < 16 then
	movlw	16
	subwf	LCDBYTE,W
	btfsc	STATUS, C
	goto	ENDIF17
;if LCDByte > 7 then
	movf	LCDBYTE,W
	sublw	7
	btfsc	STATUS, C
	goto	ENDIF18
;LCD_State = LCDByte
	movf	LCDBYTE,W
	movwf	LCD_STATE
;end if
ENDIF18
;END IF
ENDIF17
;END IF
ENDIF16
	return

;********************************************************************************

FN_LCDREADY
;LCDReady = FALSE
	clrf	LCDREADY
;LCD_RSTemp = LCD_RS
	bcf	SYSLCDTEMP,2
	btfsc	PORTD,0
	bsf	SYSLCDTEMP,2
;SET LCD_RW ON
	bsf	PORTD,1
;Wait 5 10us
	movlw	5
	movwf	SysWaitTemp10US
	call	Delay_10US
;SET LCD_RS OFF
	bcf	PORTD,0
;Wait 5 10us
	movlw	5
	movwf	SysWaitTemp10US
	call	Delay_10US
;SET LCD_Enable ON
	bsf	PORTD,2
;wait 5 10us
	movlw	5
	movwf	SysWaitTemp10US
	call	Delay_10US
;dir LCD_DB7 IN
	banksel	TRISD
	bsf	TRISD,7
;if LCD_DB7 OFF THEN LCDReady = TRUE
	banksel	PORTD
	btfsc	PORTD,7
	goto	ENDIF5
	movlw	255
	movwf	LCDREADY
ENDIF5
;SET LCD_Enable OFF
	bcf	PORTD,2
;wait 25 10us
	movlw	25
	movwf	SysWaitTemp10US
	call	Delay_10US
;LCD_RS = LCD_RSTemp
	bcf	PORTD,0
	btfsc	SYSLCDTEMP,2
	bsf	PORTD,0
	return

;********************************************************************************

LOCATE
;Set LCD_RS Off
	bcf	PORTD,0
;If LCDLine > 1 Then
	movf	LCDLINE,W
	sublw	1
	btfsc	STATUS, C
	goto	ENDIF1
;LCDLine = LCDLine - 2
	movlw	2
	subwf	LCDLINE,F
;LCDColumn = LCDColumn + LCD_WIDTH
	movlw	20
	addwf	LCDCOLUMN,F
;End If
ENDIF1
;LCDWriteByte(0x80 or 0x40 * LCDLine + LCDColumn)
	movf	LCDLINE,W
	movwf	SysBYTETempA
	movlw	64
	movwf	SysBYTETempB
	call	SysMultSub
	movf	LCDCOLUMN,W
	addwf	SysBYTETempX,W
	movwf	SysTemp1
	movlw	128
	iorwf	SysTemp1,W
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;wait 5 10us 'test
	movlw	5
	movwf	SysWaitTemp10US
	goto	Delay_10US

;********************************************************************************

;Overloaded signature: STRING:
PRINT108
;PrintLen = LEN(PrintData$)
;PrintLen = PrintData(0)
	movf	SysPRINTDATAHandler,W
	movwf	FSR
	bcf	STATUS, IRP
	btfsc	SysPRINTDATAHandler_H,0
	bsf	STATUS, IRP
	movf	INDF,W
	movwf	PRINTLEN
;If PrintLen = 0 Then Exit Sub
	movf	PRINTLEN,F
	btfsc	STATUS, Z
	return
;Set LCD_RS On
	bsf	PORTD,0
;Write Data
;For SysPrintTemp = 1 To PrintLen
	clrf	SYSPRINTTEMP
	movlw	1
	subwf	PRINTLEN,W
	btfss	STATUS, C
	goto	SysForLoopEnd1
SysForLoop1
	incf	SYSPRINTTEMP,F
;LCDWriteByte PrintData(SysPrintTemp)
	movf	SYSPRINTTEMP,W
	addwf	SysPRINTDATAHandler,W
	movwf	FSR
	bcf	STATUS, IRP
	btfsc	SysPRINTDATAHandler_H,0
	bsf	STATUS, IRP
	movf	INDF,W
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;Next
	movf	PRINTLEN,W
	subwf	SYSPRINTTEMP,W
	btfss	STATUS, C
	goto	SysForLoop1
SysForLoopEnd1
	return

;********************************************************************************

SYSMULTSUB
;dim SysByteTempA as byte
;dim SysByteTempB as byte
;dim SysByteTempX as byte
;clrf SysByteTempX
	clrf	SYSBYTETEMPX
MUL8LOOP
;movf SysByteTempA, W
	movf	SYSBYTETEMPA, W
;btfsc SysByteTempB, 0
	btfsc	SYSBYTETEMPB, 0
;addwf SysByteTempX, F
	addwf	SYSBYTETEMPX, F
;bcf STATUS, C
	bcf	STATUS, C
;rrf SysByteTempB, F
	rrf	SYSBYTETEMPB, F
;bcf STATUS, C
	bcf	STATUS, C
;rlf SysByteTempA, F
	rlf	SYSBYTETEMPA, F
;movf SysByteTempB, F
	movf	SYSBYTETEMPB, F
;btfss STATUS, Z
	btfss	STATUS, Z
;goto MUL8LOOP
	goto	MUL8LOOP
	return

;********************************************************************************

SYSREADSTRING
;Dim SysCalcTempA As Byte
;Dim SysStringLength As Byte
;Set pointer
;movf SysStringB, W
	movf	SYSSTRINGB, W
;movwf FSR
	movwf	FSR
;bcf STATUS, IRP
	bcf	STATUS, IRP
;btfsc SysStringB_H, 0
	btfsc	SYSSTRINGB_H, 0
;bsf STATUS, IRP
	bsf	STATUS, IRP
;Get length
;call SysStringTables
	call	SYSSTRINGTABLES
;movwf SysCalcTempA
	movwf	SYSCALCTEMPA
;movwf INDF
	movwf	INDF
;addwf SysStringB, F
	addwf	SYSSTRINGB, F
;goto SysStringReadCheck
	goto	SYSSTRINGREADCHECK
SYSREADSTRINGPART
;Set pointer
;movf SysStringB, W
	movf	SYSSTRINGB, W
;movwf FSR
	movwf	FSR
;decf FSR,F
;bcf STATUS, IRP
	bcf	STATUS, IRP
;btfsc SysStringB_H, 0
	btfsc	SYSSTRINGB_H, 0
;bsf STATUS, IRP
	bsf	STATUS, IRP
;Get length
;call SysStringTables
	call	SYSSTRINGTABLES
;movwf SysCalcTempA
	movwf	SYSCALCTEMPA
;addwf SysStringLength,F
	addwf	SYSSTRINGLENGTH,F
;addwf SysStringB,F
	addwf	SYSSTRINGB,F
;Check length
SYSSTRINGREADCHECK
;If length is 0, exit
;movf SysCalcTempA,F
	movf	SYSCALCTEMPA,F
;btfsc STATUS,Z
	btfsc	STATUS,Z
;return
	return
;Copy
SYSSTRINGREAD
;Get char
;call SysStringTables
	call	SYSSTRINGTABLES
;Set char
;incf FSR, F
	incf	FSR, F
;movwf INDF
	movwf	INDF
;decfsz SysCalcTempA, F
	decfsz	SYSCALCTEMPA, F
;goto SysStringRead
	goto	SYSSTRINGREAD
	return

;********************************************************************************

SysStringTables
	movf	SysStringA_H,W
	movwf	PCLATH
	movf	SysStringA,W
	incf	SysStringA,F
	btfsc	STATUS,Z
	incf	SysStringA_H,F
	movwf	PCL

StringTable1
	retlw	11
	retlw	39	;'
	retlw	78	;N
	retlw	105	;i
	retlw	99	;c
	retlw	101	;e
	retlw	32	; 
	retlw	99	;c
	retlw	111	;o
	retlw	99	;c
	retlw	107	;k
	retlw	39	;'


StringTable2
	retlw	13
	retlw	32	; 
	retlw	45	;-
	retlw	89	;Y
	retlw	111	;o
	retlw	117	;u
	retlw	114	;r
	retlw	32	; 
	retlw	77	;M
	retlw	111	;o
	retlw	116	;t
	retlw	104	;h
	retlw	101	;e
	retlw	114	;r


StringTable3
	retlw	13
	retlw	68	;D
	retlw	97	;a
	retlw	109	;m
	retlw	110	;n
	retlw	32	; 
	retlw	98	;b
	retlw	114	;r
	retlw	111	;o
	retlw	44	;,
	retlw	32	; 
	retlw	103	;g
	retlw	111	;o
	retlw	116	;t


StringTable4
	retlw	18
	retlw	101	;e
	retlw	118	;v
	retlw	101	;e
	retlw	114	;r
	retlw	121	;y
	retlw	111	;o
	retlw	110	;n
	retlw	101	;e
	retlw	32	; 
	retlw	108	;l
	retlw	97	;a
	retlw	117	;u
	retlw	103	;g
	retlw	104	;h
	retlw	105	;i
	retlw	110	;n
	retlw	103	;g
	retlw	32	; 


;********************************************************************************

URMOM
;locate(0, 0)
	clrf	LCDLINE
	clrf	LCDCOLUMN
	call	LOCATE
;print"'Nice cock'"
	movlw	low SYSSTRINGPARAM1
	movwf	SysStringB
	movlw	high SYSSTRINGPARAM1
	movwf	SysStringB_H
	movlw	low StringTable1
	movwf	SysStringA
	movlw	high StringTable1
	movwf	SysStringA_H
	call	SysReadString
	movlw	low SYSSTRINGPARAM1
	movwf	SysPRINTDATAHandler
	movlw	high SYSSTRINGPARAM1
	movwf	SysPRINTDATAHandler_H
	call	PRINT108
;locate(1, 0)
	movlw	1
	movwf	LCDLINE
	clrf	LCDCOLUMN
	call	LOCATE
;print" -Your Mother"
	movlw	low SYSSTRINGPARAM1
	movwf	SysStringB
	movlw	high SYSSTRINGPARAM1
	movwf	SysStringB_H
	movlw	low StringTable2
	movwf	SysStringA
	movlw	high StringTable2
	movwf	SysStringA_H
	call	SysReadString
	movlw	low SYSSTRINGPARAM1
	movwf	SysPRINTDATAHandler
	movlw	high SYSSTRINGPARAM1
	movwf	SysPRINTDATAHandler_H
	call	PRINT108
;wait 2000 ms
	movlw	208
	movwf	SysWaitTempMS
	movlw	7
	movwf	SysWaitTempMS_H
	call	Delay_MS
;cls()
	call	CLS
;locate(0, 0)
	clrf	LCDLINE
	clrf	LCDCOLUMN
	call	LOCATE
;print"Damn bro, got"
	movlw	low SYSSTRINGPARAM1
	movwf	SysStringB
	movlw	high SYSSTRINGPARAM1
	movwf	SysStringB_H
	movlw	low StringTable3
	movwf	SysStringA
	movlw	high StringTable3
	movwf	SysStringA_H
	call	SysReadString
	movlw	low SYSSTRINGPARAM1
	movwf	SysPRINTDATAHandler
	movlw	high SYSSTRINGPARAM1
	movwf	SysPRINTDATAHandler_H
	call	PRINT108
;locate(1, 0)
	movlw	1
	movwf	LCDLINE
	clrf	LCDCOLUMN
	call	LOCATE
;print"everyone laughing "
	movlw	low SYSSTRINGPARAM1
	movwf	SysStringB
	movlw	high SYSSTRINGPARAM1
	movwf	SysStringB_H
	movlw	low StringTable4
	movwf	SysStringA
	movlw	high StringTable4
	movwf	SysStringA_H
	call	SysReadString
	movlw	low SYSSTRINGPARAM1
	movwf	SysPRINTDATAHandler
	movlw	high SYSSTRINGPARAM1
	movwf	SysPRINTDATAHandler_H
	call	PRINT108
;wait 2000 ms
	movlw	208
	movwf	SysWaitTempMS
	movlw	7
	movwf	SysWaitTempMS_H
	call	Delay_MS
;cls()
	goto	CLS

;********************************************************************************

;Start of program memory page 1
	ORG	2048
;Start of program memory page 2
	ORG	4096
;Start of program memory page 3
	ORG	6144

 END
