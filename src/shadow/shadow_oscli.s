; OSCLI marshalling
;
; We can't really use the stack here as the command might be quite long, so
; we will have to copy it to the normal mode incoming buffer

clihandler:
.(
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
	
	lda #CMD_OSCLI
	jmp normal_command
.)

