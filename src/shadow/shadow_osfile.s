; OSFILE handling
;
; OSFILE passes args in A, X, and Y.  We need to put something else in A, so have to
; store the old value on the stack.
;
; YYXX points at a parameter block which we will copy to the bottom of the stack
; 
; The first two bytes of the parameter block point at a filename which we'll copy to
; the inbuffer.


filehandler:
.(
	; Store the operation code on the stack, the normal side will pick it up from there
	pha

	; Save the parameter block address as well - we don't have to preserve it but we
	; will need it later ourselves
	txa : pha
	tya : pha

	; Copy the parameter block to $0100
	stx srcptr : sty srcptr+1
	ldy #$11
loop:
	lda (srcptr),y : sta $0100,y
	dey : bpl loop

	; Copy the filename to the inbuffer
	ldx $0100
	ldy $0101
	jsr copy_xy_string_to_normal

	lda #CMD_OSFILE
	jsr normal_command

	; We need to preserve A and return it to the caller
	tax

	; Get the user's buffer pointer off the stack and copy back the buffer contents
	pla : sta srcptr+1
	pla : sta srcptr
	ldy #$11
loop2:
	lda $0100,y : sta (srcptr),y
	dey : bpl loop2

	; Remove the operation code from the stack, restore A, and return
	pla
	txa
	rts
.)

