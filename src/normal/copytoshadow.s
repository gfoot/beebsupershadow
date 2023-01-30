&copy_to_shadow:
.(
	; Copy Y bytes of data (up to 256, pass Y=0 for 256)
	; from normal memory pointed at by srcptr
	; to shadow memory pointed at by destptr

	; We do this using a subset of the Tube API which our hardware simulates.
	;
	; Writing a two-byte address to $feed - high byte first - initialises the
	; transfer system.
	;
	; Subsequently any data written to $fee5 is written to that address and
	; the transfer address is incremented.

	lda destptr+1 : sta $feed
	lda destptr : sta $feed

	sty transfersize
	ldy #0

loop:
	lda (srcptr),y : sta $fee5
	iny : cpy transfersize
	bne loop

	rts
.)


