; Intercept some OSBYTEs, pass others on to the normal OS

shadow_osbyte:
.(
	; Hack for VIEW - it expects Y to be zero or preserved during low OSBYTEs
	cmp #$80 : bcc lowosbyte

	cmp #$82 : beq shadow_osbyte82
    cmp #$83 : beq shadow_osbyte83
    cmp #$84 : beq shadow_osbyte84
    jmp normal_osbyte

lowosbyte:
	sty memtop+2
	jsr normal_osbyte
	ldy memtop+2
	rts

shadow_osbyte82:
	ldx #0
	ldy #0
	rts

shadow_osbyte83:
    ldx #<oshwm
    ldy #>oshwm
    rts

shadow_osbyte84:
    ldx memtop
    ldy memtop+1
    rts
.)

