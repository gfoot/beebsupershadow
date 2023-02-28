; Turn on shadow mode
sson:
.(
	; Unlock shadow mode
	sei
	sta $e000 : sta $d000 : sta $e000 : sta $c000
	; Leave interrupts disabled for now

	; Boot up and initialise shadow OS
	jsr bootup

    ;jsr printimm
    ;.byte "Initialising shadow OS", 13, 13, 0

	jsr osnewl

	; Send the initialisation command
	lda #SCMD_INIT
	jsr shadow_command

	; Chain to the post-Break handler to do the things that normally happen during reset -
	; hooking vectors with routines to pass them to Shadow mode, etc
	sec ; it only acts when the carry is set
	jsr normal_breakhandler

	rts
.)

