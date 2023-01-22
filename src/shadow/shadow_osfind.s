; OSFIND handling
;
; OSFIND passes args in A, X, and Y.  We need to put something else in A, so have to
; store the old value on the stack.
;
; For operations involving a filename, that needs to be copied across.


findhandler:
.(
	; Store the operation code on the stack, the normal side will pick it up from there
	pha

	cmp #0
	beq chain

	; Nonzero operations require a filename in YYXX
	jsr copy_xy_string_to_normal

chain:
	lda #CMD_OSFIND
	jsr normal_command

	; Discard the stacked operation code, without corrupting A or Y
	tax : pla : txa

	rts
.)

