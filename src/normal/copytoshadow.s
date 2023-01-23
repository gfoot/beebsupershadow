copy_to_shadow:
.(
	; Copy Y bytes of data (up to 256, pass Y=0 for 256)
	; from normal memory pointed at by $00/$01
	; to shadow memory pointed at by $02/$03

	; This involves switching to an asymmetric mode (reads coming from normal memory,
	; writes going to shadow memory) so we disable interrupts and stub out the NMI
	; handler.  Note that the stack is exempt from this, which is important otherwise
	; NMIs would need more careful handling.
    ;
    ; Disabling the NMI handler is rather heavy-handed and will cause some losses.  But
    ; we'll need to modify DNFS anyway to make it support shadow mode, and at that point
    ; can make its NMI handlers support this mode.

	; Disable normal interrupts
	php
	sei

	; Save the first byte of the existing NMI handler, and replace it with an RTI
	lda $0d00 : pha
	lda #$40 : sta $0d00

	; Switch to normal read, shadow write mode
	jsr normal_read_shadow_write

	dey
loop:
	lda (srcptr),y : sta (destptr),y
	dey
	cpy #$ff
	bne loop

	; Disable shadow writing, returning to pure normal mode
	jsr normal_rts

	; Restore the NMI handler and flags and return to caller
	pla
	sta $0d00
	plp
	rts
.)


