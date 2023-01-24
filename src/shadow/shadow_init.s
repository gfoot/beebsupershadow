shadow_init:
	; Default memtop - will be reduced when a language is loaded
	lda #$00 : sta memtop
	lda #$f8 : sta memtop+1

	; fall through

shadow_reboot:
    jsr initvectors

	; Clear the Escape flag
	lda #$00 : sta escapeflag
	
	jsr printimm
	.byte "SuperShadow 64K", 13, 13, 0

	jmp normal_rts

