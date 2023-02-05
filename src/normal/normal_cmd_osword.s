do_osword_impl:
.(
    ; Get osword number from X
	txa

    ; Execute the OSWORD using the parameter block in the transfer buffer
    ldx #<normal_transfer_buffer
    ldy #>normal_transfer_buffer
    jsr osword

    jmp shadow_rts
.)

do_osword00_impl:
.(
    ; The stack contains - above our return address - a valid parameter block for us to
	; use, so we just chain to osword here and let shadow mode deal with the result
    lda #$00 : ldy #$01
    tsx : inx : inx : inx
    jsr osword
	jmp shadow_rts
.)

