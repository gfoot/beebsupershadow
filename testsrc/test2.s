; Offline diagnostics for the SuperShadow V2 board

* = $2000

entry:
	; Assume shadow mode is inactive, and shadow support ROM is not present
	;
	; We should test the data transfer system first as everything else depends on it

	sei

	jsr test1
	jsr test2
	jsr test3
	jsr test4
	jsr test5
	jsr test6
	jsr test7
	jsr test8
	jsr test9

	jsr $ffe7
	lda #'O' : jsr $ffee
	lda #'K' : jsr $ffee
	jsr $ffe7 : jsr $ffe7

exit:
	cli
	ldx #<cmd_basic : ldy #>cmd_basic : jmp $fff7

cmd_basic:
	.byt "B.", 13

dofail:
	lda #"F" : jsr $ffee
	jsr $ffe7 : jsr $ffe7
	lda #"F" : jsr $ffee
	lda #"a" : jsr $ffee
	lda #"i" : jsr $ffee
	lda #"l" : jsr $ffee
	jsr $ffe7 : jsr $ffe7
	jmp exit


; Uploads some shadow code from YYXX to $0200, A bytes
upload_shadowcode:
.(
	stx $a8 : sty $a9

	ldx #0 : ldy #2 : jsr settransaddr

	tax
	ldy #0
loop:
	lda ($a8),y : sta $fee5
	iny : dex : bne loop

	; Also put a stub at $C0 to call this code in shadow mode
	ldx #$c0 : ldy #0 : jsr settransaddr
	lda #$20 : sta $fee5             ; jsr..
	sty $fee5 : lda #2 : sta $fee5   ;    ..$0200
	lda #$4c : sta $fee5             ; jmp..
	lda #$3f : sta $fee5 : sty $fee5 ;    ..$003f

	; And an RTS at $3f to return to normal mode
	lda #$60 : sta $3f

	rts
.)

; Runs the uploaded shadow code passing A,X,Y
run_shadowcode:
.(
	php : sei
	jsr $c0
	plp : rts
.)


; Set the shadow transfer address register to YYXX
settransaddr:
.(
	sty $feed

	; Issue 1 hack
	pha : tya : asl : asl : asl : asl : sta $feed : pla

	stx $feed
	rts
.)


; Write a single byte from A to the shadow memory location YYXX
shadowpoke:
.(
	jsr settransaddr
	sta $fee5
	rts
.)


; Reads a single byte from shadow memory location YYXX into A
shadowpeek:
.(
	jsr settransaddr
	lda $fee5
	rts
.)


; Check that writing single bytes via the transfer register works
test1:
.(
	lda #'1': jsr $ffee

	ldx #0 : ldy #3

	lda #'a': jsr $ffee
	lda #0 : jsr shadowpoke : jsr shadowpeek : bne fail

	lda #'b': jsr $ffee
	lda #10 : jsr shadowpoke : jsr shadowpeek : cmp #10 : bne fail

	lda #'c': jsr $ffee
	lda #20 : iny : jsr shadowpoke : jsr shadowpeek : cmp #20 : bne fail

	lda #'d': jsr $ffee
	dey : jsr shadowpeek : cmp #10 : bne fail

	lda #'e': jsr $ffee
	iny : jsr shadowpeek : cmp #20 : bne fail

	jmp $ffe7

fail:
	jmp dofail
.)


; Check that writing multiple bytes writes to consecutive memory addresses
test2:
.(
	lda #'2': jsr $ffee

	ldx #0 : ldy #3

	jsr settransaddr
	lda #0 : sta $fee5
	lda #10 : sta $fee5
	lda #20 : sta $fee5

	jsr settransaddr

	lda #'a': jsr $ffee
	lda $fee5 : bne fail

	lda #'b': jsr $ffee
	lda $fee5 : cmp #10 : bne fail

	lda #'c': jsr $ffee
	lda $fee5 : cmp #20 : bne fail

	lda #'d': jsr $ffee
	inx : jsr shadowpeek : cmp #10 : bne fail

	lda #30 : jsr shadowpoke

	lda #'e': jsr $ffee
	lda $fee5 : cmp #20 : bne fail

	dex : jsr settransaddr

	lda #'f': jsr $ffee
	lda $fee5 : cmp #0 : bne fail

	lda #'g': jsr $ffee
	lda $fee5 : cmp #30 : bne fail

	lda #'h': jsr $ffee
	lda $fee5 : cmp #20 : bne fail

	jmp $ffe7

fail:
	jmp dofail
.)


; Test that high and low shadow banks are working independently
test3
.(
	lda #'3' : jsr $ffee

	ldx #0 : ldy #0 : lda #0 : jsr shadowpoke

	ldy #$80 : lda #$ff : jsr shadowpoke

	lda #'a' : jsr $ffee
	ldy #0 : jsr shadowpeek : bne fail

	lda #'b' : jsr $ffee
	ldy #$80 : jsr shadowpeek : cmp #$ff : bne fail

	jmp $ffe7

fail:
	jmp dofail
.)



; Thorough test of all shadow RAM
test4:
.(
	lda #'4' : jsr $ffee

	; Start at $200 to avoid corrupting the stack, which is shared
	ldy #2 : ldx #0

	lda #'a' : jsr $ffee

	jsr settransaddr

	stx $70 : sty $71
	lda #>($fe00-$0200) : sta $73
	lda #0
writeloop:
	clc
	adc $70 : adc $71 : sta $fee5
	inc $70 : bne writeloop
	inc $71 : dec $73 : bne writeloop

	lda #'b' : jsr $ffee

	jsr settransaddr

	stx $70 : sty $71
	lda #>($fe00-$0200) : sta $73
	lda #0
cmploop:
	clc
	adc $70 : adc $71 : cmp $fee5 : bne fail
	inc $70 : bne cmploop
	inc $71 : dec $73 : bne cmploop

	jmp $ffe7
	

fail:
	sta $72
	jmp dofail
.)


; Test going into shadow mode and back
test5:
.(
	lda #'5' : jsr $ffee

	; We put a JMP instruction at $FD,$FE,$FF in shadow memory, that jumps to $3F in order to 
	; return to normal mode.  At $FD,$FE in normal memory we put SEC / RTS.  Then we call to
	; $FD and see if the carry gets set or not.

	lda #$60 : sta $3f     ; norm $003F  RTS

	lda #$38 : sta $fd     ; norm $00FD  SEC
	lda #$60 : sta $fe     ; norm $00FE  RTS

	ldx #$fd : ldy #0 : jsr settransaddr
	lda #$4c : sta $fee5
	lda #$3f : sta $fee5
	sty $fee5              ; shad $00FD  JMP $003F

	clc
	jsr $fd
	bcs fail

	jmp $ffe7

fail:
	jmp dofail
.)


; Test that the helper routine for uploading and running shadow code is working
test6:
.(
	lda #'6' : jsr $ffee

	ldx #<shadcode : ldy #>shadcode : lda #shadcodeend-shadcode
	jsr upload_shadowcode

	; Clear out the memory where the result gets written
	ldx #$10 : ldy #0 : jsr settransaddr
	lda #0 : sta $fee5 : sta $fee5 : sta $fee5

	lda #'a' : jsr $ffee

	lda #4 : ldx #7 : ldy #9 : jsr run_shadowcode

	cmp #5 : bne fail
	lda #'b' : jsr $ffee
	cpx #8 : bne fail
	lda #'c' : jsr $ffee
	cpy #10 : bne fail

	ldx #$10 : ldy #0 : jsr settransaddr

	lda #'d' : jsr $ffee
	lda $fee5 : cmp #4 : bne fail
	lda #'e' : jsr $ffee
	lda $fee5 : cmp #7 : bne fail
	lda #'f' : jsr $ffee
	lda $fee5 : cmp #9 : bne fail
	lda #'g' : jsr $ffee

	jmp $ffe7

fail:
	jmp dofail

shadcode:
	sta $10
	stx $11
	sty $12
	inx : iny : eor #1
	rts
shadcodeend:
.)


; Test that the stack is shared
test7:
.(
	lda #'7' : jsr $ffee

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



; Test that high and low shadow banks are working independently, from shadow code
test8
.(
	lda #'8' : jsr $ffee

	ldx #<shadcode : ldy #>shadcode : lda #shadcodeend-shadcode
	jsr upload_shadowcode

	ldx #$7f : ldy #$00 : lda #$d1 : jsr shadowpoke
	ldx #$7f : ldy #$80 : lda #$ab : jsr shadowpoke

	lda #'a' : jsr $ffee

	lda #0
	sta $0100 : sta $0101
	sta $0102 : sta $0103

	jsr run_shadowcode

	lda #'b' : jsr $ffee
	lda $0102 : cmp #$d1 : bne fail

	lda #'c' : jsr $ffee
	lda $0103 : cmp #$ab : bne fail

	lda #'d' : jsr $ffee

	lda $0100 : cmp #$cd : bne fail

	lda #'e' : jsr $ffee

	lda $0101 : cmp #$36 : bne fail

	lda #'f' : jsr $ffee

	jmp $ffe7

shadcode:
	lda $7f : sta $0102
	lda $807f : sta $0103

	lda #$cd : sta $7f
	lda #$36 : sta $807f
	
	lda $7f : sta $0100
	lda $807f : sta $0101

	rts
shadcodeend:

fail:
	jmp dofail
.)



; Thorough test of all shadow RAM via shadow code
test9:
.(
	lda #'9' : jsr $ffee

	ldx #<shadcode : ldy #>shadcode : lda #shadcodeend-shadcode
	jsr upload_shadowcode

	lda #'a' : jsr $ffee

	ldy #3 : ldx #<($fe00-0300) : lda #$e0
	jsr run_shadowcode
	sta $7f

	lda #'b' : jsr $ffee

	lda $7f : bne fail

	lda #'c' : jsr $ffee

	ldy #$ff : ldx #1 : lda #0
	jsr run_shadowcode
	sta $7f

	lda #'d' : jsr $ffee

	lda $7f : bne fail

	lda #'e' : jsr $ffee

	jmp $ffe7

fail:
	jmp dofail


shadcode:
.(
	; Y = start page, X = num pages, A = num extra bytes at end
	sta 8 : stx 9 : sty 10

	sty 1
	sta 2
	stx 3

	lda #0 : sta 0
	tax
writeloop:
	clc
	adc 0 : adc 1 : sta (0,x)
	inc 0 : bne writeloop
	inc 1 : dec 3 : bne writeloop
	ldy 2 : beq writedone
writeloop2:
	clc
	adc 0 : adc 1 : sta (0,x)
	inc 0 : dey : bne writeloop2
writedone:

	lda 8 : ldx 9 : ldy 10

	sty 1
	sta 2
	stx 3

	lda #0 : sta 0
	tax
cmploop:
	clc
	adc 0 : adc 1 : cmp (0,x) : bne sfail
	inc 0 : bne cmploop
	inc 1 : dec 3 : bne cmploop
	ldy 2 : beq cmpdone
cmploop2:
	clc
	adc 0 : adc 1 : cmp (0,x) : bne sfail
	inc 0 : dey : bne cmploop2
cmpdone:

	lda #0
	rts

sfail:
	lda #1
	rts
.)
shadcodeend:
.)


