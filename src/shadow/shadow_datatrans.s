; Shadow data transfers
; 
; Used by file loading and saving, etc
;
; Set the address first, then either read or write bytes by calling other routines one at a time.  They
; mustn't be mixed.

&shadow_data_setaddr_impl:
	stx shadow_data_write_impl+1 : stx shadow_data_read_impl+1
	sty shadow_data_write_impl+2 : sty shadow_data_read_impl+2
	jmp normal_rts

&shadow_data_write_impl:
.(
	sta $1234
	inc shadow_data_write_impl+1
	bne do_rts
	inc shadow_data_write_impl+2
do_rts:
	jmp normal_rts
.)

&shadow_data_read_impl:
.(
	lda $1234
	inc shadow_data_read_impl+1
	bne do_rts
	inc shadow_data_read_impl+2
do_rts:
	jmp normal_rts
.)

