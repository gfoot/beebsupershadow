; These entry points are standard for the Tube Host.
;
; The DNFS ROM calls entry_transfer quite a lot.  The 
; other two are called from the OS ROM, but it won't
; actually call them here at present as we don't fake
; that the Tube is present for the OS ROM

entry_copylanguage:
	rts : rts : rts

entry_syncescapestatus:
	rts : rts : rts

entry_transfer:
	; Look up the actual target address, put it in X and Y, and call shadow mode to store it
.(
	stx srcptr : sty srcptr+1

	; We only support modes 0, 1 and 4; also want to stop on claim/release
	; So don't try to poke around inside the data block for other modes
	cmp #2 : bcc readaddr
	cmp #4 : bne call_shadow_data_setaddr

readaddr:
	pha

	ldy #0
	lda (srcptr),y : tax
	iny
	lda (srcptr),y : tay

	pla

call_shadow_data_setaddr:
	jsr shadow_data_setaddr

	ldx srcptr : ldy srcptr+1
	rts
.)

