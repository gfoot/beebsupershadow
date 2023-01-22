copy_to_normal:
.(
	; Copy Y bytes of data (up to 256, pass Y=0 for 256)
	; from shadow memory pointed at by srcptr
	; to normal memory pointed at by destptr

    ; This is the direct opposite of copy_to_shadow.  We will go into shadow-read,
    ; normal-write mode, and most code won't work in that mode, so disable interrupts.
    ;
    ; NMIs are OK because they immediately switch into normal-read, normal-write mode -
    ; but we need to make sure they switch back to the right mode when they return

	; Disable normal interrupts
	php
	sei

    ; Mark that we're switching to shadow_read_normal_write mode, so that if an NMI occurs
    ; the handler will know to switch back to this mode when it's finished
    lda #$80
    sta shadow_read_normal_write_flag
	jsr shadow_read_normal_write

	dey
loop:
	lda (srcptr),y : sta (destptr),y
	dey
	cpy #$ff
	bne loop

again:
	; Return to pure shadow mode, clearing the flag
	jsr shadow_read_normal_write_off

	; Restore the processor flags and return to caller
	plp
	rts
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

