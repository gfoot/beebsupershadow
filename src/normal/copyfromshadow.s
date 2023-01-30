&copy_from_shadow:
.(
	; Copy Y bytes of data (up to 256, pass Y=0 for 256)
	; from shadow memory pointed at by srcptr
	; to normal memory pointed at by destptr

	; This uses the same mechanism as copy_to_shadow, but reading instead of
	; writing.

	lda srcptr+1 : sta $feed
	lda srcptr : sta $feed

	sty transfersize
	ldy #0

loop:
	lda $fee5 : sta (destptr),y
	iny : cpy transfersize
	bne loop

	rts
.)


&normal_copy_from_shadow_impl:
.(
	; Pick up a half-prepared transfer from shadow mode and go ahead with the
	; transfer, returning to shadow mode afterwards

	sta transfersize
	stx destptr : sty destptr+1
	ldy #0

loop:
	lda $fee5 : sta (destptr),y
	iny : cpy transfersize
	bne loop

	jmp shadow_rts
.)

