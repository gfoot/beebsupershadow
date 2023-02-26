; Offline diagnostics for the SuperShadow V1x board
;
; This is the V1 board with the v1x PLD

* = $2000

entry:
	; We start in mode 0 (unlocked).  Writing to $Exxx in normal mode locks;
	; writing $Dxxx,$Exxx,$Cxxx unlocks.
	;
	; When unlocked, executing code from $00-$7F switches to normal mode and
	; executing code from $80-$FF switches to shadow mode.
	; 
	; In normal mode, writes to F800-FFFF should write-through to Shadow RAM.
	;
	; Shadow $00C0-$00FF is mapped to normal $04C0-$04FF
	; Shadow $0300-$03FF is mapped to normal $0700-$07FF

	sei

	jsr test1
	jsr test2
	jsr test3
	jsr test4
	jsr test5
	jsr test6
	jsr test7

	lda #'O' : jsr $ffee
	lda #'K' : jsr $ffee
	jsr $ffe7

exit:
	cli
	ldx #<cmd_basic : ldy #>cmd_basic : jmp $fff7

cmd_basic:
	.byt "B.", 13

dofail:
	lda #"F" : jsr $ffee : jsr $ffe7 : jmp exit


; Returns with carry set if shadow mode is available, clear if it is locked
check_if_locked:
.(
	php
	sei

	; Set up a "normal rts" stub
	n_rts = $3f : lda #$60 : sta n_rts
	
	; Set up a fake "shadow sec" stub that doesn't set the carry
	s_sec = $f8 : sta s_sec

	; Set up the real "shadow sec" stub
	lda #$38    : sta $400+s_sec    ; sec
	lda #$4c    : sta $400+s_sec+1  ; jmp
	lda #<n_rts : sta $400+s_sec+2  ; <n_rts
	lda #>n_rts : sta $400+s_sec+3  ; >n_rts

	; Call it and check the carry flag
	clc
	jsr s_sec

	; Save the carry
	rol $70

	; Restore flags for interrupt state, restore carry, and exit
	plp
	ror $70
	rts
.)


; Uploads some shadow code from YYXX to $0300, A bytes
upload_shadowcode:
.(
	stx $a8 : sty $a9
	tay
loop:
	dey
	lda ($a8),y : sta $0700,y
	cpy #0 : bne loop

	n_rts = $3f
	lda #$60 : sta n_rts

	ldx #$c0

	lda #$20    : sta $0400,x : inx  ; jsr
	lda #<$0300 : sta $0400,x : inx  ; <$0300
	lda #>$0300 : sta $0400,x : inx  ; >$0300
	lda #$4c    : sta $0400,x : inx  ; jmp
	lda #<n_rts : sta $0400,x : inx  ; <n_rts
	lda #>n_rts : sta $0400,x : inx  ; >n_rts

	rts
.)

; Runs the uploaded shadow code passing A,X,Y
run_shadowcode:
.(
	php : sei
	jsr $c0
	plp : rts
.)



; Check shadow mode is initially unlocked, then lock it and check that works,
; then fail to unlock it and check that, then unlock it and check that
;
; This verifies that locking works, that mode switching works, and also that 
; shadow high zero page mirroring works
;
; It's not really possible to test these things independently
test1:
.(
	lda #'1': jsr $ffee

	jsr check_if_locked
	bcs notlocked

	jmp dofail

notlocked:
	lda #'a' : jsr $ffee

	sta $e000
	jsr check_if_locked
	bcc locked

	jmp dofail

locked:
	lda #'b' : jsr $ffee

	; Right sequence, but some extra writes mixed in
	php : sei
	sta $d000
	sta $e000
	sta $f000
	sta $c000
	plp
	jsr check_if_locked
	bcc locked2

	jmp dofail

locked2:
	lda #'c' : jsr $ffee

	; Get it right this time
	php : sei
	sta $d000
	sta $e000
	sta $c000
	plp
	jsr check_if_locked
	bcs unlocked2

	jmp dofail

unlocked2:
	jmp $ffe7
.)


; Check that shadow $0300 => normal $0700 redirection is working
test2:
.(
	lda #'2' : jsr $ffee

	php : sei

	; Set up a "normal rts" stub
	n_rts = $3f : lda #$60 : sta n_rts
	
	; Set up a shadow routine to read from $0300
	s_entry = $c0
	ldx #s_entry

	; Set up the real "shadow sec" stub
	lda #$8d    : sta $400,x : inx  ; sta <abs>
	lda #<$0301 : sta $400,x : inx  ; <$0301
	lda #>$0301 : sta $400,x : inx  ; >$0301
	lda #$ad    : sta $400,x : inx  ; lda <abs>
	lda #<$0300 : sta $400,x : inx  ; <$0300
	lda #>$0300 : sta $400,x : inx  ; >$0300
	lda #$4c    : sta $400,x : inx  ; jmp
	lda #<n_rts : sta $400,x : inx  ; <n_rts
	lda #>n_rts : sta $400,x : inx  ; >n_rts

	; Call it a few times and see what comes back
	lda #1 : sta $0700 : lda #9 : jsr s_entry
	sta $a8 : lda $0701 : sta $a9
	lda #8 : sta $0700 : lda #3 : jsr s_entry
	sta $aa : lda $0701 : sta $ab

	; Put the interrupts back and print some diagnostics
	plp

	lda #'a' : jsr $ffee
	lda $a8 : cmp #1 : bne fail
	lda #'b' : jsr $ffee
	lda $a9 : cmp #9 : bne fail
	lda #'c' : jsr $ffee
	lda $aa : cmp #8 : bne fail
	lda #'d' : jsr $ffee
	lda $ab : cmp #3 : bne fail
	lda #'e' : jsr $ffee
	
	jmp $ffe7

fail:
	jmp dofail
.)


; Test that the helper routine for uploading and running shadow code is working
test3:
.(
	lda #'3' : jsr $ffee

	ldx #<shadcode : ldy #>shadcode : lda #shadcodeend-shadcode
	jsr upload_shadowcode

	lda #'a' : jsr $ffee

	lda #4 : ldx #7 : ldy #9 : jsr run_shadowcode

	lda #'b' : jsr $ffee
	lda $04f0 : cmp #4 : bne fail
	lda #'c' : jsr $ffee
	lda $04f1 : cmp #7 : bne fail
	lda #'d' : jsr $ffee
	lda $04f2 : cmp #9 : bne fail
	lda #'e' : jsr $ffee

	jmp $ffe7

fail:
	jmp dofail

shadcode:
	sta $f0
	stx $f1
	sty $f2
	rts
shadcodeend:
.)


; Test that the stack is shared
test4:
.(
	lda #'4' : jsr $ffee

	ldx #<shadcode : ldy #>shadcode : lda #shadcodeend-shadcode
	jsr upload_shadowcode

	lda #'a' : jsr $ffee

	lda #4 : sta $0100 : lda #7 : tax : jsr run_shadowcode
	stx $a8 : ldx $0100 : stx $a9

	lda #'b' : jsr $ffee
	lda $a8 : cmp #4 : bne fail
	lda #'c' : jsr $ffee
	lda $a9 : cmp #7 : bne fail
	lda #'d' : jsr $ffee

	jmp $ffe7

fail:
	jmp dofail

shadcode:
	ldx $0100 : sta $0100
	rts
shadcodeend:
.)


; Test that high address write-through works
test5:
.(
	lda #'5' : jsr $ffee

	ldx #<shadcode : ldy #>shadcode : lda #shadcodeend-shadcode
	jsr upload_shadowcode

	lda #'a' : jsr $ffee

	lda #$23 : sta $f808 : sta $f909 : sta $fa0a : sta $fb0b : sta $ff0f

	lda #'b' : jsr $ffee
	jsr run_shadowcode
	
	cmp #0 : bne fail

	lda #'c' : jsr $ffee

	jmp $ffe7

fail:
	jmp dofail

shadcode:
	lda #$23
	cmp $f808 : bne sfail
	cmp $f909 : bne sfail
	cmp $fa0a : bne sfail
	cmp $fb0b : bne sfail
	cmp $ff0f : bne sfail
	lda #0
	rts
sfail:
	lda #1
	rts
shadcodeend:
.)



; Test that high and low shadow banks are working independently
test6
.(
	lda #'6' : jsr $ffee

	ldx #<shadcode : ldy #>shadcode : lda #shadcodeend-shadcode
	jsr upload_shadowcode

	lda #'a' : jsr $ffee

	lda #0 : sta $7f
	sta $0100 : sta $0101

	jsr run_shadowcode

	lda #'b' : jsr $ffee

	lda $7f : cmp #0 : bne fail

	lda #'c' : jsr $ffee

	lda $0100 : cmp #$cd : bne fail

	lda #'d' : jsr $ffee

	lda $0101 : cmp #$36 : bne fail

	lda #'e' : jsr $ffee

	jmp $ffe7

shadcode:
	lda #$cd : sta $7f
	lda #$36 : sta $807f
	
	lda $7f : sta $0100
	lda $807f : sta $0101

	rts
shadcodeend:

fail:
	jmp dofail
.)



; Thorough test of all shadow RAM
test7:
.(
	lda #'7' : jsr $ffee

	ldx #<shadcode : ldy #>shadcode : lda #shadcodeend-shadcode
	jsr upload_shadowcode

	lda #'a' : jsr $ffee

	lda #0 : sta $7f
	sta $0120 : sta $0121 : sta $0122

	jsr run_shadowcode
	sta $7f

	lda #'b' : jsr $ffee

	lda $7f : bne fail

	lda #'c' : jsr $ffee

	jmp $ffe7

fail:
	jmp dofail


shadcode:
.(
	lda #0 : sta 0
	lda #4 : sta 1
	lda #0 : tax
writeloop:
	clc
	adc 0 : adc 1 : sta (0,x)
	inc 0 : bne writeloop
	inc 1 : bne writeloop

	lda #0 : sta 0
	lda #4 : sta 1
	lda #0 : tax
cmploop:
	clc
	adc 0 : adc 1 : cmp (0,x) : bne sfail
	inc 0 : bne cmploop
	inc 1 : bne cmploop

	lda #0
	rts

sfail:
	lda #1
	rts
.)
shadcodeend:
.)

