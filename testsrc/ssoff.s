	* = $2000

entry:
.(
	sei

	; Disable shadow mode
	sta $e000

	; Restore OS vectors
	lda $ffb8
	sta $1
	lda $ffb7
	sta $0
	ldy $ffb6
loop:
	dey
	lda ($0),y : sta $0200,y
	cpy #0 : bne loop

	; Disable fake Tube
	lda #$ea : ldx #0 : ldy #0 : jsr $fff4

	; Disable BREAK intercept
	lda #247 : ldx #0 : ldy #0 : jsr $fff4

	cli

	ldy #$ff
printloop:
	iny
	lda message,y : jsr $ffe3
	cmp #13 : bne printloop

	; Reactivate filing system
	ldx #<cmd_disc
	ldy #>cmd_disc
	jsr $fff7

	; Enter BASIC
	ldx #<cmd_basic
	ldy #>cmd_basic
	jmp $fff7

cmd_disc:
	.byte "DISC", 13

cmd_basic:
	.byte "B.", 13

message:
	.byte "SuperShadow disabled", 13
.)

