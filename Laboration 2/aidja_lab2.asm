/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
;												Laboration 2 - Morse																					;
;												Datorteknik - TSIU02																					;
;												Aidin Jamshidi																							;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		.equ delay_mult = 3						//Varje �kning av talet dubblerar tiden f�r hela str�ngen att utspela sig ("3" brukar ge b�st ljud ut)

		call	HW_INIT
		jmp		MAIN
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rutiner som visar vilken text som ska spelas upp och v�rdet f�r ASCII-tecken
TEXT:											//�ndra texten inom citationstecken f�r att �ndra p� ljudet ut i morse
		.db		"AIDJA AIDJA AIDJA",$00

		.org	 0x100
ASCII:											//Bokst�ver i ordning fr�n A-Z i ASCII
		.db		$60,$88,$A8,$90,$40,$28,$D0,$08,$20,$78,$B0,$48,$E0,$A0,$F0,$68,$D8,$50,$10,$C0,$30,$18,$70,$98,$B8,$C8
;				A	B	C	D	E	F	G	H	I	J	K	L	M	N	O	P	Q	R	S	T	U	V	W	X	Y	Z
;				+0	+1	+2	+3	+4	+5	+6	+7	+8	+9	+10	+11	+12	+13	+14	+15	+16	+17	+18	+19	+20	+21	+22	+23	+24	+25
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rutiner som f�rbereder portar f�r att f� utg�ngar
HW_INIT:
		ldi		r16, 0b00010000					//V�rde f�r pinne 0-7
		out		DDRB,r16						//Pinne 4 �r utg�ng
		ret
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rutiner som f�rbereder koden med textrad m.m
MAIN:
		call	DELAY							//Extra l�ng delay innan texten b�rjas spela om f�r att f�rhindra "leakage" fr�n tidigare textspelning
		ldi		r16,LOW(RAMEND)					//F�rbereder stacken
		out		SPL,r16							//Store register to I/O location
		ldi		r16,HIGH(RAMEND)				//F�rbereder stacken
		out		SPH,r16							//Store register to I/O location
		ldi		ZH,high(TEXT*2)					//G�r s� att Z-pekare �r p� f�rsta tecknet i texten under labeln "TEXT"
		ldi		ZL,low(TEXT*2)
		ldi		r20,delay_mult					//Anv�nds f�r att f�rl�nga delayen. V�rdet �ndras under "delay_mult"
		call	MORSE
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rutiner som f�rbereder Z-pekare och vilket ASCII-tecken som  ska skickas ut i ljudform
MORSE:
		call	GET_CHAR						//Kallar till UP GET_CHAR som h�mtar ASCII-tecken och inkrementerar Z (Z+)
		cpi		r16,$20							//J�mf�r register r16 emot ASCII-tecken $20 (mellanslag)
		breq	SPACE							//Mellanrummet mellan morsekoden
		cpi		r16,$00							//J�mf�r register r16 emot ASCII-tecken $00 (slutet av texten)
		breq	MAIN							//S�ger till programmet att avsluta n�r texten �r slut
		call	LOOKUP							//H�mtar information om Z-pekare
		call	SOUND							//Med all information kallas sound f�r att ge ut morseljud
		call	MORSE							//B�rjar om med n�sta tecken ifall det finns

GET_CHAR:
		lpm		r16,Z+							//H�mtar ASCII-tecken och inkrementarar med Z (Z+)
		ret
	
LOOKUP:											//Kollar i tabellen, ASCII -> HEX
		push	ZH								//Sparar position i ASCII-tabellen
		push	ZL
		subi	r16,'A'							//Vart Z ska peka i ASCII-HEX-tabellen
		ldi		ZH,high(ASCII*2)				//F�rsta positionen i ASCII-HEX-tabellen
		ldi		ZL,low(ASCII*2)
		add		ZL,r16							//Adderar bin�ra v�rdet f�r ASCII-tecknet utan carry
		lpm		r17,Z							//Sparar bin�ra v�rdet f�r ASCII i register r17
		pop		ZL								//H�mtar n�sta position i ASCII-texten
		pop		ZH
		ret

SPACE:
		ldi		r18,7							//Mellanslag mellan karakt�rer som �r 7 g�nger l�ngre (DELAY-format)
		call	DELAY							//Kallar p� DELAY med (7n)
		jmp		MORSE

NEXT_CHAR:
		ldi		r18,3
		call	DELAY
		ret
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rutiner som skapar ljudet med hj�lp av BEEP och NOBEEP
SOUND:											//G�r igenom alla bitar
		cpi		r17,0b10000000					//Kollar om den �r klar
		breq	NEXT_CHAR						//Ifall den �r f�rdig s� g� till n�sta tecken
		lsl		r17								//N�sta bit
		brcs	LONG_BEEP						//Om C = 1 -> SEND_BEEP(3N)

SHORT_BEEP:
		ldi		r18,1							//Om C = 0 -> SEND_BEEP(N)
		jmp		SEND_BEEP

LONG_BEEP:
		ldi		r18,3							//Tre g�nger l�ngt ljud

SEND_BEEP:
		call	BEEP							//Kallar p� rutin som "ettar" utg�ng 4 i PORTB f�r att f� ljud
		call	DELAY
		ldi		r18,1
		call	NOBEEP							//Kallar p� rutin som "nollar" utg�ng 4 i PORTB f�r att inte f� n�got ljud
		call	DELAY
		jmp		SOUND
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rutiner som "ettar" och "nollar" utg�ng 4 i PORTB
BEEP:
		sbi		PORTB,4			//Set bit in I/O register - "Ettar" utg�ng 4
		ret

NOBEEP:
		cbi		PORTB,4			//Clear bit in I/O register - "Nollar" utg�ng 4
		ret
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rutiner som skapar alla DELAYS
DELAY:
		mul		r18, r20
		mov		r18, r0

DELAY_2:
		adiw	r25:r24,1
		breq	DELAY_3
		jmp		DELAY_2

DELAY_3:
		dec		r18
		brne	DELAY_2
		ret