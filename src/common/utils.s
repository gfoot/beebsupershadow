; Utility function to print a string pointed at by print_ptr
print:
.(
	pha
	txa : pha
	ldx #0
	jsr printloop
	pla : tax
	pla
	rts

; Utility function to print a constant string specified immediately 
; after the JSR instruction
&printimm:
	php
	pha : txa : pha

	tsx
	lda $104,x
	sta print_ptr
	lda $105,x
	sta print_ptr+1

	ldx #0
	jsr printloopincrement

	tsx
	lda print_ptr
	sta $104,x
	lda print_ptr+1
	sta $105,x

	pla : tax : pla
	plp
	rts

printloop:
	lda (print_ptr,x)
	beq printloopdone
	jsr osasci
printloopincrement:
	inc print_ptr
	bne printloop
	inc print_ptr+1
	jmp printloop
printloopdone:
	rts
.)

printhex:
.(
	php
	pha
	lsr : lsr : lsr : lsr
	jsr printnybble
	pla
	pha
	jsr printnybble
	pla
	plp
	rts
printnybble:
	and #15
	cmp #10
	bcc num
	adc #6
num:
	adc #48
	jsr oswrch
	rts
.)

