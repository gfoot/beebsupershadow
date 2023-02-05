; Copy a CR-terminated string from YYXX to the transfer buffer
; 
; Preserves A
;
; Updates X and Y to point to the transfer buffer's normal mode address
copy_xy_string_to_normal:
.(
	pha

	stx srcptr : sty srcptr+1

	ldy #0
loop:
	lda (srcptr),y : sta shadow_transfer_buffer,y
	cmp #13
	beq foundcr
	iny
	bne loop

	brk
	.byte 1, "Bad string", 0

foundcr:
	ldx #<normal_transfer_buffer
	ldy #>normal_transfer_buffer

	pla
	rts
.)

