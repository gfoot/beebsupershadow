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
.)

    ; Tell the shadow side what happened
    lda #SCMD_REBOOT
    jsr shadow_command    

    ; Fall through to actions we need to take in normal mode after shadow mode is
    ; initialised

normal_postshadowinit_setup:
	; Install the BRK handler as the shadow OS is ready for it now
	lda #<normal_brkhandler : sta brkv
	lda #>normal_brkhandler : sta brkv+1

	; And the event handler
	lda evntv : sta normal_eventhandler_oldevntv
	lda evntv+1 : sta normal_eventhandler_oldevntv+1
	lda #<normal_eventhandler : sta evntv
	lda #>normal_eventhandler : sta evntv+1

	; Tell the OS that the Tube is present
	lda #$ea
	ldx #$ff
	ldy #0
	jsr osbyte

    rts

