;**********************************************************************
;MUSIC BOX TUNES                                                      *
;  3-6-2010                                                           *
;Multi tune Music Box without tables - uses whole of memory!          *
;Press Sw to increment to next tune                                   *
;**********************************************************************
;
;       --+------------ +5v     
;		  |                  |  |
;    +--- | -----------------|[]|----+
;    |    |Vdd ---v---       |  |    |
;    |    +---|1   Gnd|      piezo   |
;    |        |       |              |
;    |  +-----|GP5 GP0|              |
;    |  |     |       |              |        
;    +--------|GP4 GP1|              |
;       |     |       |              |
;       |     |GP3 GP2|--------------+
;       |      -------     
;       o     PIC12F629        
;  Sw    /
;       /  
;      |
;     -+------------- 0v

	list	p=16F1829
	radix	dec
	include	"p16f1829.inc"
	
		errorlevel	-302	; Don't complain about BANK 1 Registers

; CONFIG1
; __config 0xC9E4
 __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF
; CONFIG2
; __config 0xDEFF
 __CONFIG _CONFIG2, _WRT_OFF & _PLLEN_OFF & _STVREN_ON & _BORV_LO & _LVP_OFF


;==========================================================================
;
;       Configuration Bits
;
;==========================================================================


note	equ		21h	;value of HIGH and LOW for note
gap		equ		22h ;gap between notes - uses delay "gap_1"
loops	equ		23h ;loops of HIGH/LOW for 250mS or other duration
temp1	equ		24h ;temp file for note 
melody	equ		25h ;counter for melody for switch
D1		equ		26h	;used in 250mS delay
D2		equ		27h	;used in 250mS delay

gapDel	equ		29h	;used in gap delay
tempA	equ		2Ah	;used in gap delay


;****************************************************************
;Beginning of program
;****************************************************************
		org		0x00				
SetUp	bsf		status, rp0 	;Bank 1			
       	movlw	b'00101011'		;Set TRIS  
		movwf	TRISIO	   	    ;GP2,4 outputs	GP5 input
		bcf		option_reg,7	;pull-ups enabled		
		bcf		status, rp0		;bank 0		
		movlw   07h         	;turn off Comparator 
        movwf   CMCON       	;must be placed in bank 0 
        clrf	melody       	;jump value for melody table
        btfsc	gpio,5							
		goto 	readEEPROM		;read EEPROM at start-up		
		movlw	00				;If switch pressed at turn-on; clear EEPROM		
		call	write
		goto	SetUp

;********************
;* Delays 			*
;********************
	
		
		;gap_1 produces the gap between notes each unit is 1mS
		
gap1	movlw	.30    ;.50
		movwf	gapDel
		nop
		decfsz	tempA,1		
		goto	$-2		
		decfsz	gapDel,1 ;produces loops
		goto	$-4
		retlw	00	
		
		;extra pause between notes
		
pause	movlw	.60   
		movwf	D2
		nop
		decfsz	D1,1		
		goto	$-2		
		decfsz	D2,1 ;
		goto	$-4
		retlw	00		
		

	
		;250mS second delay
		
_250mS	nop
		goto	$+1		
		decfsz 	D1,1
		goto 	_250mS
		decfsz 	D2,1
		goto 	_250mS		
		retlw 	00	
		
_1Sec	call	_250mS		
		call	_250mS		
_500mS	call	_250mS
		call	_250mS
		retlw 	00	
		
		

;************************
;* Subroutines			*
;************************		
		

		
		;produces note length 
		
length1	movwf	temp1	;put note length HIGH into "temp1"
		movwf	loops	;create number of loops to produce .25sec
		comf	loops,f	;complement note value to get loops value
		clrc			;clear carry before shifting
		rrf		loops,f	;halve the value of loops
		clrc	
		rrf		loops,w	;halve the value of loops again and put into w
		addwf	loops,w   ;to get 0.75 of original		
len1_a	movf	temp1,w
		movwf	note		
		bsf		gpio,2
		bcf		gpio,4
		goto	$+1
		goto	$+1
		goto	$+1
		nop
		decfsz	note,1
		goto	$-5	
		movf	temp1,w
		movwf	note		
		bcf		gpio,2
		bsf		gpio,4
		goto	$+1
		btfss	gpio,5
		goto	switch
		goto	$+1			
		nop		
		decfsz	note,1
		goto	$-6			
		decfsz	loops,f
		goto	len1_a		
		call	gap1	;gap between notes
		retlw	00
								
			;produces note length 
			
			
			
length2	movwf	temp1	;put note length HIGH into "temp1"
		movwf	loops	;create number of loops to produce .25sec
		comf	loops,f	;complement note value to get loops value		
		goto	len1_a
		


		;produces note length 
		
lengthX	movwf	temp1	;put note length HIGH into "temp1"
		movlw	60h
		movwf	loops	;
		goto	len1_a		
			
			;produces long note length  for Happy Birthday


length2X	movwf	temp1	;put note length HIGH into "temp1"
		movlw	0FFh
		movwf	loops	;
		goto	len1_a
		
			;read melody number from EEPROM at turn-on
readEEPROM	
		bsf		status,rp0			
		clrf	EEADR		;to read first location in EEPROM !!!							
		bsf		EECON1,0	;starts EEPROM read operation - result in EEDATA						
		movf	EEDATA,w	;move read data into w
		bcf		status,rp0
		movwf	melody     	;jump value for melody table   
		movlw	00               
		xorwf	melody,w   
		btfss	status,z
		goto	sw_M
		goto	Main
		
		
switch	call	_500mS	
		incf	melody,f
		incf	melody,f	;jump 2 bytes at a time on table		
		movf	melody,w
		call	write		;store melody value in EEPROM
sw_M	movf	melody,w
		addwf	02,1		;Add W to the Program Counter to create a jump
		call	M1
		goto	$-1
		call	M2
		goto	$-1
		call	M3
		goto	$-1
		call	M4
		goto	$-1
		call	M5
		goto	$-1
		call	M6
		goto	$-1
		call	M7
		goto	$-1
		call	M8
		goto	$-1
		call	M9
		goto	$-1
		call	M10
		goto	$-1
		call	M11
		goto	$-1	
		nop		
		btfss	gpio,5		
		goto	$-1
		call	_250mS
		clrf	melody
		goto	Main
		
write	bsf		status,rp0	;select bank1
		clrf	eeadr		;to load into first location
		movwf	eedata		;w will have melody value		
		bsf		eecon1,wren	;enable write		
		movlw	55h 		;unlock codes
		movwf	eecon2
		movlw	0aah
		movwf	eecon2
		bsf		eecon1,wr	;write begins
		bcf		status,rp0	;select bank0		
writeA	btfss	pir1,eeif	;wait for write to complete
		goto	writeA
		bcf		pir1,eeif
		bsf		status,rp0	;select bank1
		bcf		eecon1,wren	;disable other writes
		bcf		status,rp0	;select bank0					
		retlw	00		
		

;************************
;*Melodies		        *
;************************		

		;It's A Small World

M1		movlw	.151		;It's
		call 	length1
		movlw	.142		;a
		call	length1
		movlw	.128		;world
		call 	length2
		movlw	.75			;of
		call	length2
		movlw	.95			;laugh-
		call 	length2
		movlw	.84			;-ter
		call	length1
		movlw	.95			;a
		call 	length1
		movlw	.95			;world
		call	length2
		movlw	.102		;of
		call 	length2
		movlw	.102		;tears
		call	length2
		movlw	.172		;It's
		call 	length1
		movlw	.151		;a
		call	length1
		movlw	.142		;world
		call 	length2
		movlw	.84			;of
		call	length2
		movlw	.102		;hopes
		call 	length2
		movlw	.95			;and
		call	length1
		movlw	.102		;a
		call	length1
		movlw	.113		;world
		call 	length2
		movlw	.128		;of
		call	length2		
		movlw	.128		;fears
		call	length2
		movlw	.151		;There's
		call 	length1
		movlw	.142		;so
		call	length1		
		movlw	.128		;much
		call	length2
		movlw	.95			;that
		call 	length1
		movlw	.84			;we
		call	length1		
		movlw	.75			;share
		call	length2
		movlw	.84			;that
		call 	length1
		movlw	.95			;it's
		call	length1			
		movlw	.113		;time
		call	length2
		movlw	.84			;we're
		call 	length1
		movlw	.75			;a
		call	length1		
		movlw	.71			;ware
		call	length2
		call	pause		
		movlw	.75			;It's
		call 	length1
		movlw	.102		;a
		call	length1		
		movlw	.113		;small
		call	length2
		movlw	.71			;world
		call 	length2
		movlw	.75			;aft-
		call	length2		
		movlw	.84			;-ter
		call 	length1
		movlw	.95			;all
		call	length2		
		call	_250mS		
		movlw	.95			;It's
		call 	length2
		movlw	.95			;a
		call	length1		
		movlw	.75			;small
		call	length2
		movlw	.95			;world
		call 	length2
		movlw	.84			;aft-
		call	length2		
		movlw	.84			;-ter
		call 	length1
		movlw	.84			;all
		call	length2		
		call	_250mS		
		movlw	.84			;It's
		call 	length2
		movlw	.84			;a
		call	length1		
		movlw	.71			;small
		call	length2
		movlw	.84			;world
		call 	length2
		movlw	.75			;aft-
		call	length2		
		movlw	.75			;-ter
		call 	length1
		movlw	.75			;all
		call	length2			
		call	_250mS		
		movlw	.75			;It's
		call 	length2
		movlw	.75			;a
		call	length1		
		movlw	.64			;small
		call	length2
		movlw	.71			;world
		call 	length2
		movlw	.71			;aft-
		call	length2		
		movlw	.71			;-ter
		call 	length1
		movlw	.71			;all
		call	length2		
		movlw	.75			;It's
		call 	length1
		movlw	.84			;a
		call	length1		
		movlw	.128		;small
		call	length2
		movlw	.102		;small
		call	length2
		movlw	.95			;world
		call 	length2
		call	_1Sec
		retlw	00
		
		;Jingle Bells			
		
M2		movlw	.151		;E
		call 	length1
		movlw	.151		;E
		call	length1		
		movlw	.151		;E
		call	length2
		movlw	.151		;E
		call 	length1
		movlw	.151		;E
		call	length1		
		movlw	.151		;E
		call 	length2
		movlw	.151		;E
		call	length1		
		movlw	.128		;G
		call 	length1
		movlw	.192		;C
		call	length1		
		movlw	.172		;D
		call	length2
		movlw	.151		;E
		call	length2		
		call	_250mS		
		movlw	.142		;F
		call 	length1
		movlw	.142		;F
		call 	length1
		movlw	.142		;F
		call	length1		
		movlw	.142		;F
		call	length1
		movlw	.142		;F
		call 	length1
		movlw	.151		;E
		call	length1		
		movlw	.151		;E
		call 	length1
		movlw	.151		;E
		call	length1		
		movlw	.151		;E
		call 	length1
		movlw	.172		;D
		call	length1		
		movlw	.172		;D
		call	length1
		movlw	.151		;E
		call	length1		
		movlw	.172		;D
		call 	length2
		movlw	.128		;G
		call 	length2
		call	_1Sec		
		retlw	00		

		
	;Oh My Darling Clementine
	
		
M3		movlw	.128		;0
		call 	length1
		movlw	.128		;my
		call 	length1
		movlw	.128		;darl
		call	lengthx		
		movlw	.172		;ing
		call	lengthx
		call	_250mS
		movlw	.102		;0
		call 	length1
		movlw	.102		;my
		call	length1		
		movlw	.102		;darl
		call 	lengthx		
		movlw	.128		;ing	
		call	lengthx		
		call	_250mS	
			
		movlw	.128		;0
		call 	length1					
		movlw	.102		;my
		call	length1		
		movlw	.84			;dar
		call	length2
		movlw	.84			;ling
		call	lengthx		
		movlw	.95			;clem
		call 	lengthx
		movlw	.102		;en
		call 	lengthx		
		movlw	.113		;tine
		call 	lengthx
		call	_250mS
		
		movlw	.113		;you
		call 	length2
		movlw	.102		;are
		call	length2		
		movlw	.95			;lost
		call	length2				
		movlw	.95			;and
		call 	length1
		movlw	.102		;gone
		call	lengthx		
		movlw	.113		;for
		call 	lengthx
		movlw	.102		;ev
		call	lengthx		
		movlw	.128		;er
		call 	lengthx
		call	_250mS
		
		movlw	.128		;Dref	
		call	lengthx		
		movlw	.102		;ful
		call	lengthx
		movlw	.113		;sor
		call	lengthx		
		movlw	.172		;ry
		call 	lengthx
		movlw	.142		;Clen		
		call	lengthx		
		movlw	.113		;en
		call	lengthx
		movlw	.128		;tine
		call	lengthx		
		
		call	_1Sec
		retlw	00		
		
		
		;THE ENTERTAINER - from "The Sting"	
		
		
M4		movlw	.84			;1
		call 	length1
		movlw	.75			;
		call	length1		
		movlw	.95			;
		call 	length1
		movlw	.113		;
		call	length1		
		call	pause		
		movlw	.102		;
		call 	length1
		movlw	.128		;	
		call	length1	
		call	pause
		call	pause			
		movlw	.84			;
		call	length1
		movlw	.75			;
		call	length1		
		movlw	.95			;
		call 	length1
		movlw	.113		;	
		call	length1	
		call	pause	
		movlw	.102		;
		call	length1
		movlw	.128		;
		call	length2				
		movlw	.172		;2
		call 	length1
		movlw	.151		;		
		call	length2		
		movlw	.192		;	
		call 	length2		
		movlw	.227		;
		call	lengthX
		call	pause
		movlw	.202		;
		call	lengthX		
		movlw	.227		;
		call 	lengthX
		movlw	.242		;		
		call	lengthX			
		call	pause		
		movlw	.245		;
		call	lengthX
		call	pause
		movlw	.172		;
		call	length1		
		movlw	.160		;
		call 	length1		
		movlw	.151		;    3		
		call	length1		
		movlw	.95			;	
		call 	length1
		call	pause
		movlw	.151		;
		call	length1
		movlw	.95			;
		call	length1	
		call	pause	
		movlw	.151		;
		call 	length1		
		movlw	.95			;	
		call 	length2
		call	pause
		movlw	.95		;
		call	length1
		movlw	.75		;
		call	length1		
		movlw	.73		;
		call 	length1		
		movlw	.75			;	4	
		call	length1		
		movlw	.95			;	
		call 	length1		
		movlw	.85			;
		call 	length1
		movlw	.75			;		
		call	length1		
		movlw	.75			;	
		call 	length1
		movlw	.102		;
		call	length1
		movlw	.84			;
		call	length2		
		movlw	.95			;
		call 	length2
		call	pause
		movlw	.95			;		
		call	length1	
		call	pause	
		movlw	.172		;	
		call 	length1
		movlw	.160		;
		call 	length1			
		call	_1Sec		
		retlw	00
		
		
		;Twinkle Twinkle Little Star
M5		
		
		movlw	.192			;	1	
		call	length2		
		movlw	.192			;	
		call 	length2		
		movlw	.128			;
		call 	length2
		movlw	.128			;		
		call	length2		
		movlw	.113			;	
		call 	length2
		movlw	.113		;
		call	length2
		movlw	.128			;
		call	length2	
		call	_250mS	
		movlw	.142			;
		call 	length2		
		movlw	.142			;		
		call	length2				
		movlw	.151		;	
		call 	length2
		movlw	.151		;
		call 	length2
		movlw	.172			;
		call 	length2		
		movlw	.172			;		
		call	length2				
		movlw	.192		;	
		call 	length2
		call	_250mS	
		
		movlw	.128			;  2
		call 	length2
		movlw	.128			;		
		call	length2		
		movlw	.142			;
		call 	length2		
		movlw	.142			;		
		call	length2	
		movlw	.151		;	
		call 	length2
		movlw	.151		;
		call 	length2
		movlw	.172			;
		call 	length2	
		call	_250mS	
		movlw	.128			; 
		call 	length2
		movlw	.128	
		call 	length2			
		movlw	.142			;
		call 	length2		
		movlw	.142
		call 	length2			
		movlw	.151		;	
		call 	length2
		movlw	.151		;
		call 	length2
		movlw	.172			;
		call 	length2	
		call	_250mS		
		movlw	.192		;	3
		call 	length2
		movlw	.192		;	
		call 	length2
		movlw	.128			;  
		call 	length2
		movlw	.128			;		
		call	length2		
		movlw	.113			;	
		call 	length2
		movlw	.113		;
		call	length2
		movlw	.128			;  
		call 	length2
		call	_250mS
		movlw	.142			;
		call 	length2		
		movlw	.142			;		
		call	length2	
		movlw	.151		;	
		call 	length2
		movlw	.151		;
		call 	length2
		movlw	.172			;
		call 	length2	
		movlw	.172			;
		call 	length2	
		movlw	.192		;		
		call 	length2
		call	_1Sec
		retlw	00
		
		
	;You are my Sunshine
		
M6		movlw	.172		;You
		call 	length1
		movlw	.128		;are
		call 	length1
		movlw	.113		; my 
		call 	length1
		movlw	.102		;sun		
		call	length2		
		movlw	.102		;shine	
		call 	length2
		call	_250mS
		movlw	.102		;My  
		call 	length1		
		movlw	.107		;on
		call 	length1		
		movlw	.98			;ly
		call 	length1	
		movlw	.128		;sun
		call 	length2
		movlw	.128		;shine
		call 	length2
		call	_250mS
		movlw	.128		;You
		call 	length1	
		movlw	.113		;make		
		call 	length1			
		movlw	.102		;me	
		call 	length1		
		movlw	.75			;hap-  
		call 	length2
		movlw	.75			;-py		
		call	length2	
		call	_250mS	
		movlw	.75			;when	
		call 	length1
		movlw	.84			;skies
		call	length1
		movlw	.95			;are  
		call 	length1		
		movlw	.102		;grey
		call 	length2		
		call	_250mS	
		movlw	.128		;You'll	
		call 	length1
		movlw	.113		;nev
		call 	length1
		movlw	.102		;er
		call 	length1	
		movlw	.84			;know
		call 	length2	
		movlw	.75			;dear
		call 	length2
		call	_250mS
		movlw	.75		;	how
		call 	length1		
		movlw	.84			;much
		call 	length1
		movlw	.95			; I 
		call 	length1		
		movlw	.102		;3  love
		call	length2						
		movlw	.128		;you	
		call 	length2
		call	_250mS		
		movlw	.128		;please
		call 	length1		
		movlw	.113		;don't
		call 	length1
		movlw	.102		;take
		call 	length2
		movlw	.95			;my
		call 	length1	
		movlw	.113	;	sun
		call 	length2
		movlw	.113		;shine
		call 	length1
		movlw	.102		;a
		call 	length1		
		movlw	.128		;way
		call 	length2
		call	_1Sec
		retlw	00
		
		
		
M7		;Frere  Jacques
		
		movlw	.192			;1
		call 	length2	
		movlw	.172			;
		call 	length2	
		movlw	.151			;
		call 	length2	
		movlw	.192			;
		call 	length2	
		movlw	.192			;
		call 	length2	
		movlw	.172			;
		call 	length2		
		movlw	.151			;
		call 	length2	
		movlw	.192			;
		call 	length2		
		call	_250mS		
		movlw	.151			;2
		call 	length2	
		movlw	.142			;
		call 	length2	
		movlw	.128			;
		call 	lengthX	
		movlw	.151			;
		call 	length2			
		movlw	.142			;
		call 	length2			
		movlw	.128			;
		call 	lengthX	
		call	_250mS		
		movlw	.128			;3
		call 	length1	
		movlw	.113			;
		call 	length1	
		movlw	.128			;
		call 	length1	
		movlw	.142			;
		call 	length1				
		movlw	.151			;
		call 	length2			
		movlw	.192			;
		call 	length2				
		movlw	.128			;
		call 	length1	
		movlw	.113			;
		call 	length1				
		movlw	.128			;
		call 	length1			
		movlw	.142			;
		call 	length1			
		movlw	.151			;
		call 	length2				
		movlw	.192			;
		call 	length2	
		call	_250mS		
		movlw	.192			;4
		call 	lengthX				
		movlw	.204			;
		call 	lengthX	
		movlw	.192			;
		call 	lengthX				
		movlw	.192			;
		call 	lengthX
		movlw	.204			;
		call 	lengthX				
		movlw	.192			;
		call 	lengthX
		call	_1Sec		
		retlw	00
		
		
		
M8		;'O When The Saints

		movlw	.128		;oh
		call 	length1				
		movlw	.102		;when
		call 	length1	
		movlw	.95			;the
		call 	length1				
		movlw	.84			;saints
		call 	length2
		call	_250mS								
		movlw	.128		;go
		call 	length1	
		movlw	.102		;march
		call 	length1		
		movlw	.95			;ing
		call 	length1	
		movlw	.84			;in
		call 	length2
		call	_250mS		
		movlw	.128		;oh
		call 	length1						
		movlw	.102		;when
		call 	length1				
		movlw	.95			;the
		call 	length1	
		movlw	.84			;saints
		call 	length2		
		movlw	.102		;go
		call 	length2		
		movlw	.128		;march
		call 	length2		
		movlw	.102		;ing
		call 	length2		
		movlw	.113		;in		
		call 	length2
		call	_250mS		
		movlw	.102		;o
		call 	length1
		movlw	.102		;lord
		call 	length1			
		movlw	.113		;I
		call 	length1				
		movlw	.128		;want
		call 	length2				
		movlw	.128		;to
		call 	length1
		movlw	.102		;be
		call 	length2				
		movlw	.84			;in
		call 	length1	
		movlw	.84			;that
		call 	length1						
		movlw	.84			;num
		call 	length1				
		movlw	.95			;ber
		call 	length2	
		call	_250mS					
		movlw	.75			;when
		call 	length2
		movlw	.75			;the
		call 	length1				
		movlw	.84			;saints
		call 	length2
		movlw	.102		;go
		call 	length2			
		movlw	.113		;march
		call 	length2			
		movlw	.113		;ing
		call 	length1	
		movlw	.128		;in
		call 	length2		
		call	_1Sec	
		retlw	00
		
		
		
M9   ;Mary Had a little Lamb

		movlw	.151			;1
		call 	length1				
		movlw	.172			;
		call 	length1	
		movlw	.192			;
		call 	length1				
		movlw	.172			;
		call 	lengthX
		movlw	.151			;
		call 	length1				
		movlw	.151			;
		call 	length1
		movlw	.151			;
		call 	length1	
		call	_250mS		
		movlw	.171			;2
		call 	length1				
		movlw	.172			;
		call 	length1	
		movlw	.172			;
		call 	lengthX
		call	_250mS				
		movlw	.151			;
		call 	length1					
		movlw	.128			;
		call 	length1
		movlw	.128			;
		call 	lengthX	
		call	_250mS		
		movlw	.146			;3
		call 	length1				
		movlw	.172			;
		call 	length1	
		movlw	.192			;
		call 	length1				
		movlw	.172			;
		call 	length1
		movlw	.142			;
		call 	length1				
		movlw	.142			;
		call 	length1
		movlw	.142			;		
		call 	lengthX	
		call	_250mS		
		movlw	.151			;
		call 	length1		
		movlw	.172			;4
		call 	length1				
		movlw	.172			;
		call 	length1	
		movlw	.151			;
		call 	length1				
		movlw	.172			;
		call 	length1
		movlw	.192			;
		call 	lengthX	
		call	_1Sec				
		retlw	00
		
M10		;This Old Man
		
		movlw	.128			;1
		call 	length1				
		movlw	.151			;
		call 	length1	
		movlw	.128			;
		call 	lengthX
		call	_250mS			
		movlw	.128			;
		call 	length1				
		movlw	.151			;
		call 	length1	
		movlw	.128			;
		call 	lengthX
		call	_250mS						
		movlw	.113			;
		call 	length1
		movlw	.128			;
		call 	length1				
		movlw	.142			;
		call 	length1
		movlw	.151			;		
		call 	length1							
		movlw	.172			;  2
		call 	length1			
		movlw	.151			;
		call 	length1				
		movlw	.142			;
		call 	length1
		call	_250mS	
		movlw	.151			;
		call 	length1				
		movlw	.142			;
		call 	length1		
		movlw	.128			;		
		call 	lengthX
		call	pause								
		movlw	.192			;
		call 	lengthX
		call	pause				
		movlw	.192			;
		call 	length1				
		movlw	.192			;
		call 	length1	
		movlw	.192			;
		call 	lengthX			
		call	_250mS						
		movlw	.192			;3
		call 	length1
		movlw	.172			;
		call 	length1				
		movlw	.151			;
		call 	length1			
		movlw	.142			;		
		call 	length1					
		movlw	.128			;
		call 	lengthX
		call	_250mS				
		movlw	.128			;
		call 	length1			
		movlw	.172			;
		call 	length1				
		movlw	.172			;
		call 	length1				
		movlw	.142			;
		call 	length1						
		movlw	.151			;
		call 	length1			
		movlw	.172			;
		call 	length1				
		movlw	.192			;					
		call 	lengthX		
		call	_1Sec				
		retlw	00
		
		;Happy Birthday

M11		movlw	.128			;"G" -Hap
		call 	length2		
		movlw	.128			;"G"-py
		call 	length2							
		movlw	.113			;"A"  birth
		call 	length2			     
        movlw	.128			;"G"   day
		call 	length2	       
		movlw	.95				;"C"   to
		call 	length2	      
        movlw	.102			;"B"   you
		call 	length2	    
        call	_250mS	        
		movlw	.128			;"G" -Hap
		call 	length2		
		movlw	.128			;"G"-py
		call 	length2							
		movlw	.113			;"A"  birth
		call 	length2			     
        movlw	.128			;"G"   day
		call 	length2             
        movlw	.84				;"D"  to
		call 	length2			
		movlw	.95				;"C"  you
		call 	length2	
		call	_250mS			
		movlw	.128			;"G" -Hap
		call 	length2		
		movlw	.128			;"G"-py
		call 	length2	
		movlw	.64				;"G+"- BIRTH
		call 	length2x        
        movlw	.75				;"E"-day
		call 	length2x	              
        movlw	.95				;"C"  
		call 	length2        
        movlw	.102			;"B"        	 
		call 	length2			      
        movlw	.113			;"A" 
		call 	length2	
		 call	_250mS 	       
        movlw	.71				;"F" 
		call 	length2x			     
		movlw	.75				;"E" 
		call 	length2x			     
		movlw	.95				;"C"  
		call 	length2			
        movlw	.84				;"D"  
		call 	length2			
        movlw	.95				;"C"  
		call 	length2	
		call	_1Sec				
		retlw	00
		    
            
;************************
;*Main			        *
;************************		

        
Main	call	M1
		call	M1
		call	M2
		call	M2
		call	M3
		call	M3
		call	M4
		call	M4
		call	M5
		call	M5
		call	M6
		call	M6
		call	M7
		call	M7
		call	M8
		call	M8
		call	M9
		call	M9
		call	M10
		call	M10
		call	M11
		call	M11			
		goto	SetUp

				
;************************************
;*EEPROM     						*
;************************************
								
		org		2100h			
		
		de		00h,			
							
		END
		
		