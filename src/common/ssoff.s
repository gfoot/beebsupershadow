; Turn off shadow mode

; This is used as a standalone command both on disc and in ROM
;
; It requires nprintimm

ssoff:
.(
	sei

	; Disable shadow mode
	sta $e000

	; Restore OS vectors
	lda $ffb8
	sta $f9
	lda $ffb7
	sta $f8
	ldy $ffb6
loop:
	dey
	lda ($f8),y : sta $0200,y
	cpy #0 : bne loop

	; Disable fake Tube
	lda #$ea : ldx #0 : ldy #0 : jsr osbyte

	; Disable BREAK intercept
	lda #247 : ldx #0 : ldy #0 : jsr osbyte

	cli

	jsr nprintimm
	.byte 13, "SuperShadow disabled", 13, 13, 0

	rts
.)

