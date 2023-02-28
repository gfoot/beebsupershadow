	* = $2000

osasci = $ffe3
osnewl = $ffe7
osbyte = $fff4
oscli = $fff7

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
	lda #$ea : ldx #0 : ldy #0 : jsr osbyte

	; Disable BREAK intercept
	lda #247 : ldx #0 : ldy #0 : jsr osbyte

	cli

	ldy #$ff
printloop:
	iny
	lda message,y : jsr osasci
	cmp #13 : bne printloop
	jsr osnewl

	; We need to reselect the filing system, to let it adapt to Tube presence, so we
	; select the TAPE filing system and then issue service call 3 to select the 
	; default filing system like on boot-up
	lda #$8c : ldx #0 : jsr osbyte
	lda #$8f : ldx #3 : ldy #8 : jsr osbyte

	; Enter BASIC
	ldx #<cmd_basic
	ldy #>cmd_basic
	jmp oscli


cmd_basic:
	.byte "B.", 13

message:
	.byte "SuperShadow disabled", 13
.)

