; OSARGS handling
;
; X is an offset into zero page - whatever is stored there may need marshalling one way 
; or the other.  It's easiest to just do that even if it's unnecessary.
;
; A and Y need to be passed through unchanged.


argshandler:
.(
	sta $0104
	stx $0105

	lda $00,x : sta $0100
	lda $01,x : sta $0101
	lda $02,x : sta $0102
	lda $03,x : sta $0103

	lda #CMD_OSARGS
	jsr normal_command

	pha
	
	ldx $0105

	lda $0100 : sta $00,x
	lda $0101 : sta $01,x
	lda $0102 : sta $02,x
	lda $0103 : sta $03,x

	pla
	rts
.)

