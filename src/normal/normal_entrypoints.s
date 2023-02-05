; These entry points are standard for the Tube Host.
;
; The DNFS ROM calls entry_transfer quite a lot.  The 
; other two are called from the OS ROM, but it won't
; actually call them here at present as we don't fake
; that the Tube is present for the OS ROM

.(
entry_copylanguage:
	jmp copylanguage

entry_syncescapestatus:
	jmp syncescape

entry_transfer:
	; Look up the actual target address, put it in X and Y, and call shadow mode to store it
.(
	stx srcptr : sty srcptr+1

	; We only support modes 0, 1 and 4; also want to stop on claim/release
	; So don't try to poke around inside the data block for other modes
	cmp #2 : bcc readaddr
	cmp #4 : bne call_shadow_data_setaddr

readaddr:
	pha

	ldy #0
	lda (srcptr),y : tax
	iny
	lda (srcptr),y : tay

	pla

call_shadow_data_setaddr:
	jsr shadow_data_setaddr

	ldx srcptr : ldy srcptr+1
	rts
.)

copylanguage:
.(
	; Languages should enable IRQs on entry, but it looks like some don't always do 
	; that, so we'll do it here.
	cli

	; A = 0 => no language ROM found, do something
	; A = 1 => language ROM selected
	;              number in X and OSBYTE 252
	;              offset to end of name string in Y and &FD

	; Carry set => explicit language choice, so upload it
	bcs docopylanguage
	
	; If A=1 then we have a language to potentially load
	bne checksoftbreak
	
	; If A=0 then we're stuck
	brk : .byte 249, "Language?", 0

checksoftbreak:
	lda #$fd : ldx #$00 : ldy #$ff
	jsr osbyte
	cpx #0
	bne docopylanguage

	; Soft reset - like with the Tube we just rerun the previous program
	lda #SCMD_REENTERLANG
	jmp shadow_command_then_hang

docopylanguage:
	; We're going to copy a new language image and run it
	; The language is already paged in by the OS

	; The default base address for a language ROM is $8000
	lda #$00 : sta destptr
	lda #$80 : sta destptr+1
	
	; Byte 6 bit 6 indicates whether the language has a relocation address
	lda #$20 : bit $8006 : beq noreloc
	
	; Byte 7 is the offset to a zero byte before the copyright string
	; The copyright string is followed by another zero byte, and then
	; the relocation target address
	ldy $8007
skiptonextzeroloop:
	iny : lda $8000,y : bne skiptonextzeroloop
	iny ; skip the zero
	
	; Copy out the relocation address
	ldx $8000,y : sta destptr
	lda $8001,y : sta destptr+1
	
noreloc:
	; Set up the data transfer
	ldx destptr : ldy destptr+1
	lda #1 : jsr shadow_data_setaddr

	; Send the bytes
	ldx #$00 : stx srcptr
	ldx #$80 : stx srcptr+1
	ldx #$40 : ldy #$00
copyloop:
	lda (srcptr),y : jsr shadow_data_byte
	iny : bne copyloop
	inc srcptr+1 : dex : bne copyloop

	; Disable the data transfer
	lda #$80 : jsr shadow_data_setaddr

	; Enter the language
	ldx destptr : ldy destptr+1
	lda #SCMD_ENTERLANG
	jmp shadow_command_then_hang
.)

syncescape:
.(
	ldx $ff
	stx $04ff
	rts
.)

.)


; For when we don't expect a shadow command to return
shadow_command_then_hang:
.(
	jsr shadow_command

hang:
	jmp hang
.)

