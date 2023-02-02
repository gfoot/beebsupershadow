; Offline diagnostics for the SuperShadow V1 board

* = $2000

entry:
	; Set some things up to start with - we need a "normal rts" and a "normal read shadow write" rts
	; to begin with

	normal_rts = $3f
	normal_read_shadow_write_rts = $40

	lda #$60
	sta normal_rts
	sta normal_read_shadow_write_rts

	jsr test1
	jsr test2
	jsr test3
	jsr test4
	jsr test5
	jsr test6

	lda #'O' : jsr $ffee
	lda #'K' : jsr $ffee
	jsr $ffe7

exit:
	ldx #<cmd_basic : ldy #>cmd_basic : jmp $fff7

cmd_basic:
	.byt "B.", 13


dofail:
	lda #"F" : jsr $ffee : jsr $ffe7 : jmp exit


; Check whether we are now able to write to shadow memory - or at least, check that it doesn't 
; write to normal memory
test1:
.(
	lda #'1' : jsr $ffee

	test_addr = $4000

	lda #0 : sta test_addr              ; write the byte in normal mode
	lda test_addr : bne fail            ; check it's zero

	lda #'a' : jsr $ffee

	php : sei
	jsr normal_read_shadow_write_rts    ; write shadow memory
	lda #$23 : sta test_addr            ; rewrite the byte
	jsr normal_rts                      ; back to normal mode
	plp

	lda #'b' : jsr $ffee

 	lda test_addr : bne fail            ; check the byte is still zero from normal mode's perspective

	jmp $ffe7

fail:
	jmp dofail
.)


; We can try that again but writing to the stack page this time - the stack is common between 
; modes, so we expect a different result here
test2:
.(
	lda #'2' : jsr $ffee

	test_addr2 = $0123

	lda #0 : sta test_addr2             ; write the byte in normal mode
	lda test_addr2 : bne fail           ; check it's zero

	lda #'a' : jsr $ffee

	php : sei
	jsr normal_read_shadow_write_rts    ; write shadow memory
	lda #$23 : sta test_addr2           ; rewrite the byte
	jsr normal_rts                      ; back to normal mode
	plp

	lda #'b' : jsr $ffee

	lda test_addr2 : beq fail           ; this time we do expect it to have changed

	jmp $ffe7

fail:
	jmp dofail
.)


; Now let's write "JMP normal_rts" into high shadow zero page and see if we come back after calling it
test3:
.(
	lda #'3' : jsr $ffee

	php : sei
	jsr normal_read_shadow_write_rts    ; write shadow memory
	lda #$4C : sta $c0                  ; write JMP
	lda #<normal_rts : sta $c1          ;   ...
	lda #>normal_rts : sta $c2          ;   ...
	jsr normal_rts                      ; back to normal mode
	plp
	
	lda #'a' : jsr $ffee

	php : sei
	jsr $c0
	plp

	lda #'b' : jsr $ffee

	jmp $ffe7
.)


; There's also the shadow-read-normal-write mode that we could test
test4
.(
	lda #'4' : jsr $ffee

	php : sei
	jsr normal_read_shadow_write_rts    ; write shadow memory

	ldx #shadcodeend-shadcode-1
loop:
	lda shadcode,x : sta $80,x          ; copy from shadcode to $80
	dex : bpl loop

	jsr normal_rts                      ; back to normal mode
	plp
	
	lda #'a' : jsr $ffee

	lda #0 : sta $7f : sta $0123
	lda #$cd
	php : sei
	jsr $80
	plp

	lda #'b' : jsr $ffee

	lda $7f : cmp #$cd : bne fail

	lda #'c' : jsr $ffee

	lda $0123 : cmp #$cd : bne fail

	lda #'d' : jsr $ffee

	jmp $ffe7

shadcode:
	sta $7f
	sta $f8
	sta $0123
	jmp normal_rts
shadcodeend:

fail:
	jmp dofail
.)


; Test that high and low shadow banks are working independently
test5
.(
	lda #'5' : jsr $ffee

	php : sei
	jsr normal_read_shadow_write_rts    ; write shadow memory

	ldx #shadcodeend-shadcode-1
loop:
	lda shadcode,x : sta $c0,x          ; copy from shadcode to $c0
	dex : bpl loop

	jsr normal_rts                      ; back to normal mode
	plp
	
	lda #'a' : jsr $ffee

	lda #0 : sta $7f
	sta $0100 : sta $0101

	php : sei
	jsr $c0
	plp

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

	jmp normal_rts
shadcodeend:

fail:
	jmp dofail
.)

test6:
.(
	lda #'6' : jsr $ffee

	php : sei
	jsr normal_read_shadow_write_rts    ; write shadow memory

	ldx #shadcodeend-shadcode-1
loop:
	lda shadcode,x : sta $c0,x          ; copy from shadcode to $c0
	dex : bpl loop

	jsr normal_rts                      ; back to normal mode
	plp
	
	lda #'a' : jsr $ffee

	lda #0 : sta $7f
	sta $0120 : sta $0121 : sta $0122

	php : sei
	jsr $c0
	ror $7f
	plp

	lda #'b' : jsr $ffee

	lda $7f : bmi fail

	lda #'c' : jsr $ffee

	jmp $ffe7

shadcode:
.(
	lda #0 : sta 0
	lda #2 : sta 1
	lda #0 : tax
writeloop:
	clc
	adc 0 : adc 1 : sta (0,x)
	inc 0 : bne writeloop
	inc 1 : bne writeloop

	lda #0 : sta 0
	lda #2 : sta 1
	lda #0 : tax
cmploop:
	clc
	adc 0 : adc 1 : cmp (0,x) : bne sfail
	inc 0 : bne cmploop
	inc 1 : bne cmploop

	clc
	jmp normal_rts

sfail:
	sec
	jmp normal_rts
.)
shadcodeend:

fail:
	jmp dofail
.)

