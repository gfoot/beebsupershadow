* = $2000
loadaddr:

; *RUN entry - strings together things that would happen at various different 
; stages in the ROM version
execaddr:
.(
	jsr bootup

    ;jsr printimm
    ;.byte "Initialising shadow OS", 13, 13, 0

	; Send the initialisation command
	lda #SCMD_INIT
	jsr shadow_command

	; Chain to the post-Break handler to do the things that normally happen during reset -
	; hooking vectors with routines to pass them to Shadow mode, etc
	sec ; it only acts when the carry is set
	jsr normal_breakhandler

	; We need to reselect the filing system, to let it adapt to Tube presence, so we
	; select the TAPE filing system and then issue service call 3 to select the 
	; default filing system like on boot-up
	lda #$8c : ldx #0 : jsr osbyte
	lda #$8f : ldx #3 : ldy #8 : jsr osbyte

	; Read currently-active language ROM number into X
	lda #$fc : ldx #0 : ldy #$ff : jsr osbyte

	; Reactivate the language ROM specified by X, causing it to get copied to shadow
	; RAM and executed there
	lda #$8e : jsr osbyte
	
    ; If it returns somehow, we can't really carry on as we've corrupted BASIC's 
	; zero page and set weird vectors, so just hang.  This code also may no longer exist
	; in memory at that time.
hang:
	jmp hang
.)

