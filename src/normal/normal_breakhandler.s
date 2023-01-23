; Intercept "Break" in order to reactivate the Shadow OS
;
; This is called with the carry clear fairly early in initialisation, then later with
; the carry set.  We want to jump in on the second call, and re-activate the Tube flag.
; This is late enough that DNFS won't try to initialise the Tube itself, but early enough 
; that the OS will invite us to deal with language activation.

normal_breakhandler:
.(
    bcs secondtime
    rts

secondtime:

    ; Tell the shadow side what happened
    lda #SCMD_REBOOT
    jsr shadow_command    

	; Install the BRK handler as the shadow OS should still be ready for it
	lda #<normal_brkhandler : sta brkv
	lda #>normal_brkhandler : sta brkv+1

	; Tell the OS that the Tube is present
	lda #$ea
	ldx #$ff
	ldy #0
	jsr osbyte

    rts
.)

