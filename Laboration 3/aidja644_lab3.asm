/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
;													Datorteknik																;
;													TSIU02																	;
;													Laboration 3															;
;													Digitalur																;
;													Aidin Jamshidi															;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		jmp		HW_INIT												//Kallar p� HW_INIT f�r att f�rbereda Atmega328p	

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Databassegment
		.dseg
TIME:
		.byte	6													//SS:MM:HH
LINE:
		.byte	17													//Begr�nsar oss till 17 bytes p� sk�rmen d�r 16 anv�nds och 17 �r "0"
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Kodsegment
		.cseg
		.equ	FN_SET = $2B
		.equ	DISP_ON = $0F
		.equ	LCD_CLR = $01
		.equ	E_MODE = $06
		.equ	E = 1
		.equ	RS = 0
		.equ	SECOND_TICKS = 62500 - 1							//Ger en sekunds avbrott n�r TIMER1_INIT �r inl�st - @ 16/256 MHz
		.equ	HOURHIGH = TIME+5
		.equ	HOURLOW = TIME+4

		.org	OC1Aaddr											//Avbrotts-adress
		jmp		AVBROTT												//Avbrotts-rutin
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//F�rbereding av hardware
HW_INIT:															//Underprogram f�r f�rberedelse av portar m.m
		ldi		r16,HIGH(RAMEND)									//F�rbereder pekare
		out		SPH,r16
		ldi		r16,LOW(RAMEND)
		out		SPL,r16
		ldi		r16,0b00000111										//Laddar v�rdet "1" i bitarna 0-2 i register r16
		out		DDRB,r16											//Best�mmer utg�ngar
		ldi		r16,0b11110000										//Laddar v�rdet "1" i bitarna 4-7 i register r16
		out		DDRD,r16											//Best�mmer utg�ngar
		call	LCD_INIT											//Kallar p� underprogram som inneh�ller rutiner f�r "f�rberedelse" av LCD-display
		jmp		MAIN												//Hoppar till start av programmet

AVBROTT:
		push	r16													//Sparar en kopia
		in		r16,SREG											//L�gger in SREG
		call	TIME_TICK											//Kallar avbrottet(rutinen)
		out		SREG,r16											//Lagrar tillbaka SREG
		pop		r16													//Skickar till register r16
		reti

LCD_INIT:															//Underprogram f�r f�rberedelse av LCD-display
		call	WAIT												//Kallar p� rutin med 4 millisekunders delay
		call	BACKLIGHT_ON										//Kallar p� rutin som startar backlight p� LCD-display
		ldi		r16,$30												//Magin som g�r att siffror mellan 0-9 fungerar - BCD-kodar fr�n ASCII 
		call	LCD_WRITE4
		call	LCD_WRITE4
		call	LCD_WRITE4
		ldi		r16,$20												//Magin som g�r att siffror mellan 0-9 fungerar - BCD-kodar fr�n ASCII
		call	LCD_WRITE4
		ldi		r16,FN_SET											//4-bit mode, 2 line, 5x8 font
		call	LCD_COMMAND											//Kallar p� rutin som skickar displaykommandon
		ldi		r16,DISP_ON											//Display on, cursor on, cursor blink
		call	LCD_COMMAND											//Kallar p� rutin som skickar displaykommandon
		ldi		r16,LCD_CLR											//Clear display
		call	LCD_COMMAND											//Kallar p� rutin som skickar displaykommandon
		ldi		r16,E_MODE											//Increment cursor, no shift
		call	LCD_COMMAND											//Kallar p� rutin som skickar displaykommandon
		clr		r16													//Rensar register r16 f�r att f�rhindra tecken vid n�sta rad
		sts		LINE+16,r16											//S�tter "0" p� linje 17 f�r att f�rhindra mer tecken
		ldi		XH,HIGH(TIME)										//Tvingar in tiden 23:59:50 f�r att se vad som sker vid midnatt
		ldi		XL,LOW(TIME)										
		ldi		r20,$00												//Ental-sekund = 0
		st		X+,r20												//Laddar in siffran in i SRAM fr�n register r20
		ldi		r20,$05												//Tiotal-sekund = 5
		st		X+,r20												//Laddar in siffran in i SRAM fr�n register r20
		ldi		r20,$09												//Ental-minut = 9
		st		X+,r20												//Laddar in siffran in i SRAM fr�n register r20
		ldi		r20,$05												//Tiotal-minut = 5
		st		X+,r20												//Laddar in siffran in i SRAM fr�n register r20
		ldi		r20,$03												//Ental-timme = 3
		st		X+,r20												//Laddar in siffran in i SRAM fr�n register r20
		ldi		r20,$02												//Tiotal-timme = 2
		st		X+,r20												//Laddar in siffran in i SRAM fr�n register r20
		call	TIMER1_INIT											//INIT f�r avbrotts-rutin
		sei															//Set interrupt flag - Kan f� f�rsta avbrott som hoppar upp till rad 29
		ret
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Huvudprogram
MAIN:	
		call	TIME_FORMAT											//Kallar p� rutin f�r formatering av tiden
		call	LINE_PRINT											//Kallar p� rutin som skriver ut tiden p� display
		jmp		MAIN												//Loopar tillbaka till sig sj�lv
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogram till LCD
BACKLIGHT_ON:
		sbi		PORTB,2												//Set bit in I/O register - Startar backlight p� LCD-display genom att �ndra port
		ret

LCD_COMMAND:														//Rutin som skickar displaykommandon
		cbi		PORTB,RS											//Clear bit in i/O register - (RS = 0)
		call	LCD_WRITE8
		ret

LCD_HOME:															//Rutin som st�ller cursorn p� rutan h�gst upp till v�nster ($00)
		ldi		r16,$02	
		call	LCD_COMMAND
		ret

LCD_WRITE4:															//Rutin f�r 8-bitar till LCD-display
		sbi		PORTB,E												//Set bit in I/O register - E = 1 
		out		PORTD,r16											//Store register to I/O location
		nop nop nop nop												//No operation - 4 g�nger
		cbi		PORTB,E
		call	WAIT
		ret

LCD_WRITE8:															//Rutin f�r 16-bitar till LCD-display
		call	LCD_WRITE4
		swap	r16
		call	LCD_WRITE4
		swap	r16
		ret

LCD_PRINT:															//Rutin som skriver ut p� LCD-display		
		ld		r16,Z+
		cpi		r16,$00												//J�mf�r ifall n�sta "tecken" �r en nolla
		breq	DONE
		call	LCD_ASCII
		rjmp	LCD_PRINT
DONE:																//Rutin f�r LCD-PRINT
		ret

LCD_ERASE:															//Rutin som rensar LCD-display
		ldi		r16,LCD_CLR
		call	LCD_COMMAND
		ret

LCD_ASCII:															//Rutin f�r ASCII-tecken till LCD-display
		sbi		PORTB,RS
		call	LCD_WRITE8
		ret

LINE_PRINT:															//Rutin som laddar vilken rad som ska skrivas ut p� och sedan kallar p� LCD_PRINT
		call	LCD_HOME
		ldi		ZH,HIGH(LINE)										
		ldi		ZL,LOW(LINE)
		call	LCD_PRINT
		ret
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogram f�r tidomslag
TIME_TICK:															//Rutin f�r uppr�ckning av tid
		push	XL													//Sparar SREG i STACK
		push	XH													//Sparar SREG i STACK
		push	r16													//Sparar SREG i STACK

		ldi		XH,HIGH(TIME)										//Laddar pekare med formatet SS:MM:HH
		ldi		XL,LOW(TIME)
ENTAL_COMPLETE:
		ld		r16,X												//Laddar register r16 med v�rdet i X-pekare
		inc		r16													//Inkrementerar r16 med "1" f�r varje k�rning tills 10 sekunder �r n�dda
		cpi		r16,10												//�r det 10 sekunder?
		brne	KLAR
		clr		r16													//Rensar register r16
		st		X+,r16												//Laddar v�rdet fr�n register r16 till SRAM med X-pekare
TIOTAL_COMPLETE:
		ld		r16,X												//Laddar register r16 med v�rdet i X-pekare
		inc		r16													//inkrementerar r16 f�r att se ifall vi har n�tt 6-tiotalsekunder
		cpi		r16,6												//Har vi n�tt 60 sekunder?
		brne	KLAR
		clr		r16													//Rensar register r16
		st		X+,r16												//Laddar v�rdet i register r16 till X-pekare
		jmp		ENTAL_COMPLETE
KLAR:
		st		X,r16												//Ladda v�rdet i r16 till X-pekare
		rcall	MIDNATT												//�r det midnatt?
		pop		r16													//Pop register from STACK
		pop		XH													//Pop register from STACK
		pop		XL													//Pop register from STACK
		ret

MIDNATT:															//Rutin som kollar ifall det �r midnatt och om det �r midnatt st�ller om sig sj�lv till 00:00:00
		lds		r16,HOURLOW
		subi	r16,4
		lds		r16,HOURHIGH
		sbci	r16,2
		brne	M_DONE
		clr		r16
		sts		HOURLOW,r16
		sts		HOURHIGH,r16
M_DONE:
		ret
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogran f�r formatering av text
TIME_FORMAT:														//Underprogram som sk�ter formatering av tid och rader
		call	TIMEINIT
		rcall	TIME_FORMAT_SELECT
		ret

TIMEINIT:															//Rutin som laddar Y-pekare och Z-pekare med TIME och LINE
		ldi		YH,HIGH(TIME+6)
		ldi		YL,LOW(TIME+6)
		ldi		ZH,HIGH(LINE)
		ldi		ZL,LOW(LINE)
		ret

TIME_FORMAT_SELECT:
		ldi		r17,3												//Skapar formatet HH:MM:SS med v�rdet 3 - "2" ger bara ut "HH:MM"
NEXT_SEG:															//Hoppar till n�sta "segment" "HH:MM:SS" d�r tiderna �r olika segment
		rcall	SEG_FORMAT
		dec		r17
		brne	NEXT_SEG
		clr		r16
		st		-Z,r16
		ret

SEG_FORMAT:
		push	r17													//Sparar SREG i STACK
		ldi		r17,2												//Skapar segmentet med v�rdet "2" f�r att f� tv� "HH", tv� "MM" och tv� "SS"
NEXT_NUM_FORMAT:
		ld		r16,-Y												//Laddar v�rdet i Y-pekare till register r16
		subi	r16,-$30											
		st		Z+,r16												//Laddar v�rdet i register r16 till Z-pekare (SRAM)
		dec		r17													//Dekrementerar register r17
		brne	NEXT_NUM_FORMAT
		ldi		r16,$3A												//Laddar register r16 med ":" tecken
		st		Z+,r16												//Laddar upp ":" tecken i SRAM med hj�lp av Z-pekare
		pop		r17													//Pop register from STACK
		ret
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogram som hj�lper till med diverse saker
WAIT:																//4 milisekunders delay
		sbiw	r24,4												//�ndra mellan 4/8 f�r att f� en cool "ljudv�g" p� LCD-display
		brne	WAIT
		ret

TIMER1_INIT:
		ldi		r16,(1<<WGM12)|(1<<CS12)							//CTC , prescale 256
		sts		TCCR1B,r16
		ldi		r16,HIGH(SECOND_TICKS)
		sts		OCR1AH,r16
		ldi		r16,LOW(SECOND_TICKS)
		sts		OCR1AL,r16
		ldi		r16,(1<<OCIE1A)										//allow to interrupt
		sts		TIMSK1,r16
		ret