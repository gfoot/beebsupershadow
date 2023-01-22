shadow_init:
.(
    jsr initvectors

	; Default memtop - will be reduced when a language is loaded
	lda #$00 : sta memtop
	lda #$f8 : sta memtop+1

    jsr printimm
    .byte 13, "SuperShadow OS 64K", 13, 13, 0

    ;jsr shadow_test

    jmp normal_rts
.)

