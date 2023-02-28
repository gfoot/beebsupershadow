; OSCLI marshalling
;
; We can't really use the stack here as the command might be quite long, so
; we will have to copy it to the normal mode incoming buffer

clihandler:
.(
	pha
	stx srcptr : sty srcptr+1

	ldy #0

skipspacesloop:
	jsr skipspaces : iny
	cmp #'*' : beq skipspacesloop
	dey

	clc : tya : adc srcptr : sta srcptr
	lda #0 : adc srcptr+1 : sta srcptr+1

	ldx #<(cmdstr_help - cmdstrs) : jsr checkcmdstr : beq cmd_help
	ldx #<(cmdstr_go - cmdstrs) : jsr checkcmdstr : beq cmd_go

passthrough:	
	ldx srcptr : ldy srcptr+1
	jsr copy_xy_string_to_normal

	lda #CMD_OSCLI
	jsr normal_command

	pla : rts

cmd_help:
.(
	jsr printimm
	.byte 13, "SuperShadow OS 0.22 (V2/V4)", 13, 0

	jmp passthrough
.)

cmd_go:
.(
	; Y = index of non-letter after "GO"
	lda (srcptr),y : cmp #$0d : beq noaddress

	jsr skipspaces_skipone
	jsr scanhex
	jsr skipspaces
	cmp #$0d : bne passthrough   ; more parameters?

	txa : beq noaddress

	; user supplied address
	ldx destptr : ldy destptr+1
	jmp go

noaddress:
	; default address
	ldx memtop : ldy memtop+1

go:
	jsr wrapped_entercode

	pla : rts
.)



cmdstrs:
cmdstr_help: .byte "HELP", 0 : .word cmd_help
cmdstr_go:   .byte "GO", 0	 : .word cmd_go
	
checkcmdstr:
.(
	ldy #0
	lda (srcptr),y 
loop:
	and #$df                              ; ignore case
	cmp #'A' : bcc loopend                ; next not a letter
	cmp #'[' : bcs loopend                ; next is a letter
	cmp cmdstrs,x : bne return            ; return NE if letter doesn't match
	inx : iny                             ; next character
	lda (srcptr),y : cmp #'.' : bne loop  ; if it's not a dot, loop
return:
	rts     ; Z set if matched
loopend:
    ; The command word ended - return Z if the template ended too
	lda cmdstrs,x
	rts
.)

.)
