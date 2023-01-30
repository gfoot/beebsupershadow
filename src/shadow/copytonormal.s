copy_to_normal:
.(
	; Copy Y bytes of data (up to 256, pass Y=0 for 256)
	; from shadow memory pointed at by srcptr
	; to normal memory pointed at by destptr

	; We actually do this by entering normal mode and telling it to do the
    ; copy in the reverse direction.

	; Set the source address in the hardware
	lda srcptr+1 : sta $feed
	lda srcptr : sta $feed

	; Put the number of bytes in A, with YYXX pointing to the target address
	tya : ldx destptr : ldy destptr+1

	; Chain to the normal-mode routine
	jmp normal_copy_from_shadow
.)


; Copy a CR-terminated string from YYXX to the normal mode inbuffer
; 
; Preserves A
;
; Updates X and Y to point to the inbuffer
copy_xy_string_to_normal:
.(
	pha

	stx srcptr : sty srcptr+1
	lda #<normal_inbuffer : sta destptr
	lda #>normal_inbuffer : sta destptr+1

	ldy #0
loop:
	lda (srcptr),y
	cmp #13
	beq foundcr
	iny
	bne loop

	brk
	.byte 1, "Bad string", 0

foundcr:
	iny
	jsr copy_to_normal

	ldx #<normal_inbuffer
	ldy #>normal_inbuffer

	pla
	rts
.)

