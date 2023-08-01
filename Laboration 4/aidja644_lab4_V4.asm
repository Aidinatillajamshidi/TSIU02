///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
;																	Datorteknik																			  ;
;																	TSIU02																				  ;
;																	Laboration 4																		  ;
;																	Radeditor																			  ;
;																	Aidin Jamshidi																		  ;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		jmp		START												//Hoppar till rutin "START"

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Databassegment
		.dseg
COLUM: 
		.byte	17
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Kodsegment
		.cseg
		.equ	FN_SET = $2B
		.equ	DISP_ON = $0F
		.equ	LCD_CLR = $01
		.equ	E_MODE = $06
		.equ	E = $01
		.equ	RS = $00
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogram: F�rberedning av Arduino
START:
		call	HW_INIT												//F�rbereder Arduino med portar
		call	LCD_INIT											//F�rbereder LCD-display
		ldi		ZH,HIGH(COLUM)										//Laddar pekare med COLUMN
		ldi		ZL,LOW(COLUM)
		ldi		r16,'Z'
		ldi		r28,0
		call	LETTERS												//Tillkallar rutin "LETTERS"
		jmp		MAIN												//Startar MAIN-loop

HW_INIT:															//Underprogram f�r f�rberedelse av portar m.m
		ldi		r16,0b00000111										//Laddar v�rdet "1" i bitarna 0-2 i register r16
		out		DDRB,r16											//Best�mmer utg�ngar
		ldi		r16,0b11110000										//Laddar v�rdet "1" i bitarna 4-7 i register r16
		out		DDRD,r16											//Best�mmer utg�ngar
		ret

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
		ret

LETTERS:															//Rutin som hj�lper till med tecken-hantering
		inc		r28
		st		Z+,r16
		cpi		r28,31
		brne	LETTERS
		ldi		ZH,HIGH(COLUM)										//Laddar Z-pekare H�G med COLUM
		ldi		ZL,LOW(COLUM)										//Laddar Z-pekare L�G med COLUM
		ldi		r18,0
		ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Huvudprogram: Program som loopar sig
MAIN:																//MAIN-loop
		call	KEY_READ											//Rutin som ger tillbaka v�rde 1-5 vilket som sedan anv�nds f�r att v�lja knapp
		call	LCD_COL												//Rutin som anv�nder v�rdet 1-5 f�r att best�mma vilken knapp det �r som "egentligen" blev nedtryckt
		jmp		MAIN												//Starta om MAIN-loop
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogram: Hantering av knapp-tryck
LCD_COL:															//Rutin som kollar vilken knapp som har blivit nedtryckt
		cpi		r16,2												//J�mf�r register r16 med v�rdet "2" f�r att se ifall det �r knapp "LEFT" som blev nedtryckt
		breq	LEFT												//Rutin "LEFT" f�r knappen LEFT
		cpi		r16,5												//J�mf�r register r16 med v�rdet "5" f�r att se ifall det �r knapp "RIGHT" som blev nedtryckt
		breq	RIGHT												//Rutin "RIGHT" f�r knappen RIGHT
		cpi		r16,1												//J�mf�r register r16 med v�rdet "1" f�r att se ifall det �r knapp "SELECT" som blev nedtryckt
		breq	SELECT												//Rutin "SELECT" f�r knappen SELECT
		cpi		r16,3												//J�mf�r register r16 med v�rdet "3" f�r att se ifall det �r knapp "DOWN" som blev nedtryckt
		breq	UP													//Rutin "UP" f�r knappen UP
		cpi		r16,4												//J�mf�r register r16 med v�rdet "4" f�r att se ifall det �r knapp "UP" som blev nedtryckt
		breq	DOWN												//Rutin "DOWN" f�r knappen DOWN
LEFT:																//Rutin som kollar ifall knappen LEFT har blivit nedtryckt
		cpi		r18,0
		breq	LCD_COL_RETURN
		ld		r16,-Z
		ld		r16,-Z
		ldi		r16,0b00010000
		call	LCD_COMMAND											//Rutin f�r displaykommandon
		dec		r18
		jmp		LCD_COL_RETURN
RIGHT:																//Rutin som kollar ifall knappen RIGHT har blivit nedtryckt
		cpi		r18,15
		breq	LCD_COL_RETURN
		ld		r16,Z+
		ld		r16,Z+
		ldi		r16,0b00010100
		call	LCD_COMMAND											//Rutin f�r displaykommandon
		inc		r18
		jmp		LCD_COL_RETURN
SELECT:																//Rutin som startar eller st�nger av BACKLIGHT till LCD-display beroende p� ifall knappen SELECT �r nedtryckt
		sbis	PORTB, 2											//Skip if bit in I/O register is set
		jmp		BACKLIGHT_ON										//Rutin som startar BACKLIGHT till LCD-display
		jmp		BACKLIGHT_OFF										//Rutin som st�nger av BACKLIGHT till LCD-display
		jmp		LCD_COL_RETURN
UP:																	//Rutin som kollar ifall knappen UP har blivit nedtryckt och kollar vilket tecken som ska vara n�st
		ld		r16,Z
		cpi		r16,'Z'
		brne	NOT_ZA												//Kollar rutinen f�r att kontrollera n�sta tecken och sedan spara
Z_TO_A:																//Rutin som g�r igenom tecken i ordningen Z till A
		ldi		r16,'A'
		jmp		LCD_COL_UPDOWN_RETURN
NOT_ZA:
		inc		r16
		jmp		LCD_COL_UPDOWN_RETURN								//Om inte jmp finns s� rinner koden rakt ner och skapar problem med knapp-trycken

DOWN:																//Rutin som kollar ifall knappen DOWN har blivit nedtryckt och kollar vilket tecken som ska vara n�st
		ld		r16,Z
		cpi		r16,'A'
		brne	NOT_AZ												//Kollar rutinen f�r att kontrollera n�sta tecken och sedan spara
A_TO_Z:																//Rutin som g�r igenom tecken i ordningen A till Z
		ldi		r16,'Z'
		jmp		LCD_COL_UPDOWN_RETURN
NOT_AZ:
		dec		r16
LCD_COL_UPDOWN_RETURN:
		st      Z,r16
        call    LCD_ASCII
		ldi		r16,0b00010000
		call	LCD_COMMAND											//Rutin f�r displaykommandon
		jmp		LCD_COL_RETURN
LCD_COL_RETURN:														//Rutin som anv�nds f�r BREQ i "LEFT" och "RIGHT" rutinen
		ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogram: Rutiner f�r hantering av knapptryck och AD-hantering
KEY_READ:															//Rutin som sammarbetar med "KEY_WAIT_FOR_PRESS" f�r att inv�nta ett knapptryck och sedan AD-omvandling
		call	KEY
		tst		r16
		brne	KEY_READ
KEY_WAIT_FOR_PRESS:													//Rutin som inv�ntar knapptryck
		call	KEY
		tst		r16
		breq	KEY_WAIT_FOR_PRESS
		ret

KEY:																//Rutin som kollar efter vad f�r v�rde som registret har f�r att omvandla sedan till ett knapptryck
		call	ADC_READ8
		ldi		r17,217
		cp		r16,r17
		brsh	ZERO												//Blev det knapp "0"? (INGEN knapp)
		ldi		r17,159
		cp		r16,r17
		brsh	ONE													//Blev det knapp "1"? (SELECT-knapp)
		ldi		r17,76
		cp		r16,r17
		brsh	TWO													//Blev det knapp "2"? (LEFT-knapp)
		ldi		r17,50
		cp		r16,r17
		brsh	THREE												//Blev det knapp "3"? (DOWN-knapp)
		ldi		r17,24
		cp		r16,r17
		brsh	FOUR												//Blev det knapp "4"? (UP-knapp)
		ldi		r17,0
		cp		r16,r17
		brsh	FIVE												//Blev det knapp "5"? (RIGHT-knapp)
		jmp		KEY

ZERO:																//Rutin f�r "knapp 0" enligt tabell i PDF f�r laborationen
		ldi		r16,0
		jmp		KEY_RETURN

ONE:																//Rutin f�r "knapp 1" enligt tabell i PDF f�r laborationen
		ldi		r16,1
		jmp		KEY_RETURN

TWO:																//Rutin f�r "knapp 2" enligt tabell i PDF f�r laborationen
		ldi		r16,2
		jmp		KEY_RETURN

THREE:																//Rutin f�r "knapp 3" enligt tabell i PDF f�r laborationen
		ldi		r16,3
		jmp		KEY_RETURN

FOUR:																//Rutin f�r "knapp 4" enligt tabell i PDF f�r laborationen
		ldi		r16,4
		jmp		KEY_RETURN

FIVE:																//Rutin f�r "knapp 5" enligt tabell i PDF f�r laborationen
		ldi		r16,5
		jmp		KEY_RETURN

KEY_RETURN:
		ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogram: Rutiner f�r AD-omvandling
ADC_READ8:															//Rutin f�r config av AD-omvandling
		ldi		r16,(1<<REFS0)|(1<<ADLAR)|0							//F�rst v�ljer vi AVcc, Sedan att ADLAR ska vara aktivt (v�nsterjusterad) och sedan ADC0 (som 0 ger)
		sts		ADMUX,r16											//Store to SRAM
		ldi		r16,(1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
		sts		ADCSRA,r16

CONVERT:															//Startar omvandling
		lds		r16,ADCSRA
		ori		r16,(1<<ADSC)
		sts		ADCSRA,r16

ADC_BUSY:															//Wait	
		lds		r16,ADCSRA											//Load from DATA SPACE
		sbrc	r16,ADSC											//Skip if bit in register is cleared
		jmp		ADC_BUSY
		lds		r16,ADCH											//Load from DATA SPACE
		ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogram: Rutiner f�r LCD-display
LCD_COMMAND:														//Rutin som skickar displaykommandon
		cbi		PORTB,RS											//Clear bit in i/O register - (RS = 0)
		call	LCD_WRITE8
		ret

LINE_PRINT:															//Rutin som laddar vilken rad som ska skrivas ut p� och sedan kallar p� LCD_PRINT
		ldi		ZH,HIGH(COLUM)										//Laddar Z-pekare H�G med COLUM	
		ldi		ZL,LOW(COLUM)										//Laddar Z-pekare L�G med COLUM
		call	LCD_PRINT											//Tillkallar rutin f�r att skriva ut
		ret

LCD_PRINT:															//Rutin som skriver ut p� LCD-display
		call	LCD_ASCII
		ret

LCD_ASCII:															//Rutin f�r ASCII-tecken till LCD-display
		sbi		PORTB,RS
		call	LCD_WRITE8
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
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogram: Hj�lp-rutiner
BACKLIGHT_ON:														//Rutin f�r start av backlight on till LCD-display
		sbi		PORTB,2
		jmp		BACKLIGHT_RETURN

BACKLIGHT_OFF:														//Rutin f�r backlight off till LCD-display
		cbi		PORTB,2
		jmp		BACKLIGHT_RETURN

BACKLIGHT_RETURN:
		ret

WAIT:																//4 milisekunders delay
		sbiw	r24,4
		brne	WAIT
		ret