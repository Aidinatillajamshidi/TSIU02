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
//Underprogram: Förberedning av Arduino
START:
		call	HW_INIT												//Förbereder Arduino med portar
		call	LCD_INIT											//Förbereder LCD-display
		ldi		ZH,HIGH(COLUM)										//Laddar pekare med COLUMN
		ldi		ZL,LOW(COLUM)
		ldi		r16,'Z'
		ldi		r28,0
		call	LETTERS												//Tillkallar rutin "LETTERS"
		jmp		MAIN												//Startar MAIN-loop

HW_INIT:															//Underprogram för förberedelse av portar m.m
		ldi		r16,0b00000111										//Laddar värdet "1" i bitarna 0-2 i register r16
		out		DDRB,r16											//Bestämmer utgångar
		ldi		r16,0b11110000										//Laddar värdet "1" i bitarna 4-7 i register r16
		out		DDRD,r16											//Bestämmer utgångar
		ret

LCD_INIT:															//Underprogram för förberedelse av LCD-display
		call	WAIT												//Kallar på rutin med 4 millisekunders delay
		call	BACKLIGHT_ON										//Kallar på rutin som startar backlight på LCD-display
		ldi		r16,$30												//Magin som gör att siffror mellan 0-9 fungerar - BCD-kodar från ASCII 
		call	LCD_WRITE4
		call	LCD_WRITE4
		call	LCD_WRITE4
		ldi		r16,$20												//Magin som gör att siffror mellan 0-9 fungerar - BCD-kodar från ASCII
		call	LCD_WRITE4
		ldi		r16,FN_SET											//4-bit mode, 2 line, 5x8 font
		call	LCD_COMMAND											//Kallar på rutin som skickar displaykommandon
		ldi		r16,DISP_ON											//Display on, cursor on, cursor blink
		call	LCD_COMMAND											//Kallar på rutin som skickar displaykommandon
		ldi		r16,LCD_CLR											//Clear display
		call	LCD_COMMAND											//Kallar på rutin som skickar displaykommandon
		ldi		r16,E_MODE											//Increment cursor, no shift
		call	LCD_COMMAND											//Kallar på rutin som skickar displaykommandon
		ret

LETTERS:															//Rutin som hjälper till med tecken-hantering
		inc		r28
		st		Z+,r16
		cpi		r28,31
		brne	LETTERS
		ldi		ZH,HIGH(COLUM)										//Laddar Z-pekare HÖG med COLUM
		ldi		ZL,LOW(COLUM)										//Laddar Z-pekare LÅG med COLUM
		ldi		r18,0
		ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Huvudprogram: Program som loopar sig
MAIN:																//MAIN-loop
		call	KEY_READ											//Rutin som ger tillbaka värde 1-5 vilket som sedan används för att välja knapp
		call	LCD_COL												//Rutin som använder värdet 1-5 för att bestämma vilken knapp det är som "egentligen" blev nedtryckt
		jmp		MAIN												//Starta om MAIN-loop
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogram: Hantering av knapp-tryck
LCD_COL:															//Rutin som kollar vilken knapp som har blivit nedtryckt
		cpi		r16,2												//Jämför register r16 med värdet "2" för att se ifall det är knapp "LEFT" som blev nedtryckt
		breq	LEFT												//Rutin "LEFT" för knappen LEFT
		cpi		r16,5												//Jämför register r16 med värdet "5" för att se ifall det är knapp "RIGHT" som blev nedtryckt
		breq	RIGHT												//Rutin "RIGHT" för knappen RIGHT
		cpi		r16,1												//Jämför register r16 med värdet "1" för att se ifall det är knapp "SELECT" som blev nedtryckt
		breq	SELECT												//Rutin "SELECT" för knappen SELECT
		cpi		r16,3												//Jämför register r16 med värdet "3" för att se ifall det är knapp "DOWN" som blev nedtryckt
		breq	UP													//Rutin "UP" för knappen UP
		cpi		r16,4												//Jämför register r16 med värdet "4" för att se ifall det är knapp "UP" som blev nedtryckt
		breq	DOWN												//Rutin "DOWN" för knappen DOWN
LEFT:																//Rutin som kollar ifall knappen LEFT har blivit nedtryckt
		cpi		r18,0
		breq	LCD_COL_RETURN
		ld		r16,-Z
		ld		r16,-Z
		ldi		r16,0b00010000
		call	LCD_COMMAND											//Rutin för displaykommandon
		dec		r18
		jmp		LCD_COL_RETURN
RIGHT:																//Rutin som kollar ifall knappen RIGHT har blivit nedtryckt
		cpi		r18,15
		breq	LCD_COL_RETURN
		ld		r16,Z+
		ld		r16,Z+
		ldi		r16,0b00010100
		call	LCD_COMMAND											//Rutin för displaykommandon
		inc		r18
		jmp		LCD_COL_RETURN
SELECT:																//Rutin som startar eller stänger av BACKLIGHT till LCD-display beroende på ifall knappen SELECT är nedtryckt
		sbis	PORTB, 2											//Skip if bit in I/O register is set
		jmp		BACKLIGHT_ON										//Rutin som startar BACKLIGHT till LCD-display
		jmp		BACKLIGHT_OFF										//Rutin som stänger av BACKLIGHT till LCD-display
		jmp		LCD_COL_RETURN
UP:																	//Rutin som kollar ifall knappen UP har blivit nedtryckt och kollar vilket tecken som ska vara näst
		ld		r16,Z
		cpi		r16,'Z'
		brne	NOT_ZA												//Kollar rutinen för att kontrollera nästa tecken och sedan spara
Z_TO_A:																//Rutin som går igenom tecken i ordningen Z till A
		ldi		r16,'A'
		jmp		LCD_COL_UPDOWN_RETURN
NOT_ZA:
		inc		r16
		jmp		LCD_COL_UPDOWN_RETURN								//Om inte jmp finns så rinner koden rakt ner och skapar problem med knapp-trycken

DOWN:																//Rutin som kollar ifall knappen DOWN har blivit nedtryckt och kollar vilket tecken som ska vara näst
		ld		r16,Z
		cpi		r16,'A'
		brne	NOT_AZ												//Kollar rutinen för att kontrollera nästa tecken och sedan spara
A_TO_Z:																//Rutin som går igenom tecken i ordningen A till Z
		ldi		r16,'Z'
		jmp		LCD_COL_UPDOWN_RETURN
NOT_AZ:
		dec		r16
LCD_COL_UPDOWN_RETURN:
		st      Z,r16
        call    LCD_ASCII
		ldi		r16,0b00010000
		call	LCD_COMMAND											//Rutin för displaykommandon
		jmp		LCD_COL_RETURN
LCD_COL_RETURN:														//Rutin som används för BREQ i "LEFT" och "RIGHT" rutinen
		ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogram: Rutiner för hantering av knapptryck och AD-hantering
KEY_READ:															//Rutin som sammarbetar med "KEY_WAIT_FOR_PRESS" för att invänta ett knapptryck och sedan AD-omvandling
		call	KEY
		tst		r16
		brne	KEY_READ
KEY_WAIT_FOR_PRESS:													//Rutin som inväntar knapptryck
		call	KEY
		tst		r16
		breq	KEY_WAIT_FOR_PRESS
		ret

KEY:																//Rutin som kollar efter vad för värde som registret har för att omvandla sedan till ett knapptryck
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

ZERO:																//Rutin för "knapp 0" enligt tabell i PDF för laborationen
		ldi		r16,0
		jmp		KEY_RETURN

ONE:																//Rutin för "knapp 1" enligt tabell i PDF för laborationen
		ldi		r16,1
		jmp		KEY_RETURN

TWO:																//Rutin för "knapp 2" enligt tabell i PDF för laborationen
		ldi		r16,2
		jmp		KEY_RETURN

THREE:																//Rutin för "knapp 3" enligt tabell i PDF för laborationen
		ldi		r16,3
		jmp		KEY_RETURN

FOUR:																//Rutin för "knapp 4" enligt tabell i PDF för laborationen
		ldi		r16,4
		jmp		KEY_RETURN

FIVE:																//Rutin för "knapp 5" enligt tabell i PDF för laborationen
		ldi		r16,5
		jmp		KEY_RETURN

KEY_RETURN:
		ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogram: Rutiner för AD-omvandling
ADC_READ8:															//Rutin för config av AD-omvandling
		ldi		r16,(1<<REFS0)|(1<<ADLAR)|0							//Först väljer vi AVcc, Sedan att ADLAR ska vara aktivt (vänsterjusterad) och sedan ADC0 (som 0 ger)
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
//Underprogram: Rutiner för LCD-display
LCD_COMMAND:														//Rutin som skickar displaykommandon
		cbi		PORTB,RS											//Clear bit in i/O register - (RS = 0)
		call	LCD_WRITE8
		ret

LINE_PRINT:															//Rutin som laddar vilken rad som ska skrivas ut på och sedan kallar på LCD_PRINT
		ldi		ZH,HIGH(COLUM)										//Laddar Z-pekare HÖG med COLUM	
		ldi		ZL,LOW(COLUM)										//Laddar Z-pekare LÅG med COLUM
		call	LCD_PRINT											//Tillkallar rutin för att skriva ut
		ret

LCD_PRINT:															//Rutin som skriver ut på LCD-display
		call	LCD_ASCII
		ret

LCD_ASCII:															//Rutin för ASCII-tecken till LCD-display
		sbi		PORTB,RS
		call	LCD_WRITE8
		ret

LCD_WRITE4:															//Rutin för 8-bitar till LCD-display
		sbi		PORTB,E												//Set bit in I/O register - E = 1 
		out		PORTD,r16											//Store register to I/O location
		nop nop nop nop												//No operation - 4 gånger
		cbi		PORTB,E
		call	WAIT
		ret

LCD_WRITE8:															//Rutin för 16-bitar till LCD-display
		call	LCD_WRITE4
		swap	r16
		call	LCD_WRITE4
		swap	r16
		ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Underprogram: Hjälp-rutiner
BACKLIGHT_ON:														//Rutin för start av backlight on till LCD-display
		sbi		PORTB,2
		jmp		BACKLIGHT_RETURN

BACKLIGHT_OFF:														//Rutin för backlight off till LCD-display
		cbi		PORTB,2
		jmp		BACKLIGHT_RETURN

BACKLIGHT_RETURN:
		ret

WAIT:																//4 milisekunders delay
		sbiw	r24,4
		brne	WAIT
		ret