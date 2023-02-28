; Reinitialise the filing system and enter a language
init_fs_enter_language:
.(
	; We need to reselect the filing system, to let it adapt to Tube presence, so we
	; select the TAPE filing system and then issue service call 3 to select the 
	; default filing system like on boot-up

	; Select TAPE filing system initially
	lda #$8c : ldx #0 : jsr osbyte

	; Wait for no keys pressed
waitnokeysloop:
	lda #$7a : jsr osbyte
	cpx #$ff : bne waitnokeysloop

	; Issue ROM service call 3 to initialise a filing system
	lda #$8f : ldx #3 : ldy #8 : jsr osbyte

	; Read currently-active language ROM number into X
	lda #$fc : ldx #0 : ldy #$ff : jsr osbyte

	; Reactivate the language ROM specified by X, causing it to get copied to shadow
	; RAM and executed there
	lda #$8e : jsr osbyte
	
    ; If it returns somehow, we can't really carry on as we've corrupted BASIC's 
	; zero page and set weird vectors, so reboot.
	jmp ($fffc)

.)

