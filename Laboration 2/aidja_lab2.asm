/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
;												Laboration 2 - Morse																					;
;												Datorteknik - TSIU02																					;
;												Aidin Jamshidi																							;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		.equ delay_mult = 3						//Varje ökning av talet dubblerar tiden för hela strängen att utspela sig ("3" brukar ge bäst ljud ut)

		call	HW_INIT
		jmp		MAIN
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rutiner som visar vilken text som ska spelas upp och värdet för ASCII-tecken
TEXT:											//Ändra texten inom citationstecken för att ändra på ljudet ut i morse
		.db		"AIDJA AIDJA AIDJA",$00

		.org	 0x100
ASCII:											//Bokstäver i ordning från A-Z i ASCII
		.db		$60,$88,$A8,$90,$40,$28,$D0,$08,$20,$78,$B0,$48,$E0,$A0,$F0,$68,$D8,$50,$10,$C0,$30,$18,$70,$98,$B8,$C8
;				A	B	C	D	E	F	G	H	I	J	K	L	M	N	O	P	Q	R	S	T	U	V	W	X	Y	Z
;				+0	+1	+2	+3	+4	+5	+6	+7	+8	+9	+10	+11	+12	+13	+14	+15	+16	+17	+18	+19	+20	+21	+22	+23	+24	+25
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rutiner som förbereder portar för att få utgångar
HW_INIT:
		ldi		r16, 0b00010000					//Värde för pinne 0-7
		out		DDRB,r16						//Pinne 4 är utgång
		ret
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rutiner som förbereder koden med textrad m.m
MAIN:
		call	DELAY							//Extra lång delay innan texten börjas spela om för att förhindra "leakage" från tidigare textspelning
		ldi		r16,LOW(RAMEND)					//Förbereder stacken
		out		SPL,r16							//Store register to I/O location
		ldi		r16,HIGH(RAMEND)				//Förbereder stacken
		out		SPH,r16							//Store register to I/O location
		ldi		ZH,high(TEXT*2)					//Gör så att Z-pekare är på första tecknet i texten under labeln "TEXT"
		ldi		ZL,low(TEXT*2)
		ldi		r20,delay_mult					//Används för att förlänga delayen. Värdet ändras under "delay_mult"
		call	MORSE
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rutiner som förbereder Z-pekare och vilket ASCII-tecken som  ska skickas ut i ljudform
MORSE:
		call	GET_CHAR						//Kallar till UP GET_CHAR som hämtar ASCII-tecken och inkrementerar Z (Z+)
		cpi		r16,$20							//Jämför register r16 emot ASCII-tecken $20 (mellanslag)
		breq	SPACE							//Mellanrummet mellan morsekoden
		cpi		r16,$00							//Jämför register r16 emot ASCII-tecken $00 (slutet av texten)
		breq	MAIN							//Säger till programmet att avsluta när texten är slut
		call	LOOKUP							//Hämtar information om Z-pekare
		call	SOUND							//Med all information kallas sound för att ge ut morseljud
		call	MORSE							//Börjar om med nästa tecken ifall det finns

GET_CHAR:
		lpm		r16,Z+							//Hämtar ASCII-tecken och inkrementarar med Z (Z+)
		ret
	
LOOKUP:											//Kollar i tabellen, ASCII -> HEX
		push	ZH								//Sparar position i ASCII-tabellen
		push	ZL
		subi	r16,'A'							//Vart Z ska peka i ASCII-HEX-tabellen
		ldi		ZH,high(ASCII*2)				//Första positionen i ASCII-HEX-tabellen
		ldi		ZL,low(ASCII*2)
		add		ZL,r16							//Adderar binära värdet för ASCII-tecknet utan carry
		lpm		r17,Z							//Sparar binära värdet för ASCII i register r17
		pop		ZL								//Hämtar nästa position i ASCII-texten
		pop		ZH
		ret

SPACE:
		ldi		r18,7							//Mellanslag mellan karaktärer som är 7 gånger längre (DELAY-format)
		call	DELAY							//Kallar på DELAY med (7n)
		jmp		MORSE

NEXT_CHAR:
		ldi		r18,3
		call	DELAY
		ret
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rutiner som skapar ljudet med hjälp av BEEP och NOBEEP
SOUND:											//Går igenom alla bitar
		cpi		r17,0b10000000					//Kollar om den är klar
		breq	NEXT_CHAR						//Ifall den är färdig så gå till nästa tecken
		lsl		r17								//Nästa bit
		brcs	LONG_BEEP						//Om C = 1 -> SEND_BEEP(3N)

SHORT_BEEP:
		ldi		r18,1							//Om C = 0 -> SEND_BEEP(N)
		jmp		SEND_BEEP

LONG_BEEP:
		ldi		r18,3							//Tre gånger långt ljud

SEND_BEEP:
		call	BEEP							//Kallar på rutin som "ettar" utgång 4 i PORTB för att få ljud
		call	DELAY
		ldi		r18,1
		call	NOBEEP							//Kallar på rutin som "nollar" utgång 4 i PORTB för att inte få något ljud
		call	DELAY
		jmp		SOUND
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Rutiner som "ettar" och "nollar" utgång 4 i PORTB
BEEP:
		sbi		PORTB,4			//Set bit in I/O register - "Ettar" utgång 4
		ret

NOBEEP:
		cbi		PORTB,4			//Clear bit in I/O register - "Nollar" utgång 4
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