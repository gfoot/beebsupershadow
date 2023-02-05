; Main command entry point
;
; A = command code
; X,Y = parameters
&shadow_command_impl:
.(
    cmp #SCMD_INIT : beq do_init
	cmp #SCMD_CALL : beq do_call
	cmp #SCMD_ENTERLANG : beq do_enterlang
	cmp #SCMD_REBOOT : beq do_reboot
	cmp #SCMD_REENTERLANG : beq do_reenterlang

    brk
    .db $fa, "Unknown command", 0

do_init:
    jmp shadow_init

; Re-enter the language after Break is pressed
do_reenterlang:
	ldx memtop
	ldy memtop+1
	; fall through

; This is called on first boot, given XY pointing at the language ROM image
do_enterlang:
	; Enter with carry clear as this is probably during bootup
	clc
	jsr entercode

	; It shouldn't really return, and nor should we really - should put a command prompt
	; here maybe
	jmp normal_rts

; This is here in case it's useful, I think it's not currently used though.
do_call:
	jsr wrapped_entercode
	jmp normal_rts

do_reboot:
	jmp shadow_reboot
.)


