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

	; Issue a *DISC command so that DNFS reinitialises with its Tube support enabled
	ldx #<cmd_disc
	ldy #>cmd_disc
	jsr oscli

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
	
cmd_disc:
	.byte "DISC", 13
.)

