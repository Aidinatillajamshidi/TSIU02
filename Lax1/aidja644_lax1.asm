
		jmp		START

		.equ	FN_SET = $2B
		.equ	DISP_ON = $0F
		.equ	LCD_CLR = $01
		.equ	E_MODE = $06
		.equ	E = $01
		.equ	RS = $00
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		.dseg
COLUM:
		.byte 17
		.cseg
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
HW_INIT:
		ldi		r16,0b11110111
		out		ddrb,r16
		out		ddrd,r16
		ret

LCD_INIT:
		call	DELAY
		call	BACKLIGHT_ON
		ldi		r16,$30
		call	LCD_WRITE4
		call	LCD_WRITE4
		call	LCD_WRITE4
		ldi		r16,$20
		call	LCD_WRITE4
		ldi		r16,FN_SET
		call	LCD_COMMAND
		ldi		r16,DISP_ON
		call	LCD_COMMAND
		ldi		r16,LCD_CLR
		call	LCD_COMMAND
		ldi		r16,E_MODE
		call	LCD_COMMAND
		ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
START:
	call	HW_INIT
	call	LCD_INIT
	ldi		zH,HIGH(COLUM)
	ldi		zL,LOW(COLUM)
	ldi		r16,'Z'
	ldi		r28,0
AAA:
	inc		r28
	st		z+,r16
	cpi		r28,31
	brne	AAA

	ldi		zH,HIGH(COLUM)
	ldi		zL,LOW(COLUM)
	ldi		r18,0
	//sts		CURSOR,r18
MAIN:
	call LCD_HOME
	call	KEY_READ
	call	LCD_COL
	jmp		MAIN
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	LCD_HOME:
	ldi		r16,$2
	call	LCD_COMMAND
	ret

LCD_ASCII:
	sbi		portb,RS
	call	LCD_WRITE8
	ret

LCD_COMMAND:
	cbi		portb,RS
	call	LCD_WRITE8
	ret

LCD_PRINT:
	st		z,r16
	call	LCD_ASCII
	ldi		r16,0b00010000
	call	LCD_COMMAND
	ret

LCD_COL:
	cpi		r16,2
	breq	LEFT
	cpi		r16,5
	breq	RIGHT
	cpi		r16,1
	breq	SELECT
	cpi		r16,3
	breq	UP
	cpi		r16,4
	breq	DOWN
DONE:
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
BLANK:
	ldi		r16,LCD_CLR
	call	LCD_COMMAND
	ret
LEFT:
	ldi		r19, 2
	call	LCD_COMMAND
	jmp		DONE
RIGHT:
	ldi		r19, 5
	call	LCD_COMMAND
	jmp		DONE
UP:
	ldi		r19, 4
	call	LCD_COMMAND
	jmp		DONE
DOWN:
	ldi		r19, 3
	call	LCD_COMMAND
	jmp		DONE
SELECT:
	call	BLANK
	cpi		r19,2
	breq	PRINT_LEFT
	cpi		r19,3
	breq	PRINT_UP
	cpi		r19,4
	breq	PRINT_DOWN
	cpi		r19,5
	breq	PRINT_RIGHT
	cpi		r19,6
	breq	NOWHERE
	jmp		DONE

NOWHERE:
	ret

PRINT_RIGHT:
	ldi		r16,'*'
	call	LCD_ASCII
	ldi		r16,'*'
	call	LCD_ASCII
	ldi		r16,'*'
	call	LCD_ASCII
	ldi		r16,'*'
	call	LCD_ASCII
	ldi		r16,'*'
	call	LCD_ASCII
	call	LCD_COMMAND
	clr		r19
	jmp		DONE

PRINT_LEFT:
	ldi		r16,'*'
	call	LCD_ASCII
	ldi		r16,'*'
	call	LCD_ASCII
	call	LCD_COMMAND
	clr		r19
	jmp		DONE
PRINT_DOWN:
	ldi		r16,'*'
	call	LCD_ASCII
	ldi		r16,'*'
	call	LCD_ASCII
	ldi		r16,'*'
	call	LCD_ASCII
	call	LCD_COMMAND
	clr		r19
	jmp		DONE
PRINT_UP:
	ldi		r16,'*'
	call	LCD_ASCII
	ldi		r16,'*'
	call	LCD_ASCII
	ldi		r16,'*'
	call	LCD_ASCII
	ldi		r16,'*'
	call	LCD_ASCII
	call	LCD_COMMAND
	clr		r19
	jmp		DONE

KEY: 
	call	ADC_READ8
	ldi		r17,207
	cp		r16,r17
	brsh	ZERO
	ldi		r17,131 
	cp		r16,r17
	brsh	ONE
	ldi		r17,83
	cp		r16,r17
	brsh	TWO
	ldi		r17,45
	cp		r16,r17
	brsh	THREE
	ldi		r17,12
	cp		r16,r17
	brsh	FOUR
	ldi		r17,0 
	cp		r16,r17
	brsh	FIVE

ONE:
	ldi		r16,1
	jmp		DONE
TWO:
	ldi		r16,2
	jmp		DONE
THREE:
	ldi		r16,3
	jmp		DONE
FOUR:
	ldi		r16,4
	jmp		DONE
FIVE:
	ldi		r16,5
	jmp		DONE
ZERO:
	ldi		r16,0
	jmp		DONE

KEY_READ:
	call	KEY
	tst		r16
	brne	KEY_READ
KEY_WAIT_FOR_PRESS:
	call	KEY
	tst		r16
	breq	KEY_WAIT_FOR_PRESS
	ret

LCD_ERASE:
	ldi		r16,LCD_CLR
	call	LCD_COMMAND
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
ADC_READ8:
	ldi		r16,(1<<REFS0)|(1<<ADLAR)|0
	sts		ADMUX,r16
	ldi		r16,(1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
	sts		ADCSRA,r16

CONVERT:
	lds		r16,ADCSRA
	ori		r16,(1<<ADSC)
	sts		ADCSRA,r16

ADC_WAIT:
	lds		r16,ADCSRA
	sbrc	r16,ADSC
	jmp		ADC_WAIT
	lds		r16,ADCH
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LCD_WRITE4:
	sbi		portb,E
	out		portd,r16
	cbi		portb,E
	call	DELAY
	ret

LCD_WRITE8:
	call	LCD_WRITE4
	swap	r16
	call	LCD_WRITE4
	ret
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
BACKLIGHT_ON:
	sbi		portb,2
	ret

DELAY:
    ldi		r24,209
DELAY1:
	ldi		r25,255
DELAY2:
    dec		r25
    brne	DELAY2
    dec		r24
    brne	DELAY1
    ret