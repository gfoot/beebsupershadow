; OSCLI marshalling
;
; We can't really use the stack here as the command might be quite long, so
; we will have to copy it to the normal mode incoming buffer

clihandler:
.(
	jsr copy_xy_string_to_normal

	lda #CMD_OSCLI
	jmp normal_command
.)

