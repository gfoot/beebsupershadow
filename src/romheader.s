; ROMs start at $8000
* = $8000

.(
    .byte 0,0,0
    jmp service_entry
    .byte $82
    .byte <(copyrightstring-1)
    .byte 1
    .byte "SuperShadow", 0
copyrightstring:
    .byte "(C)2023 gfoot", 0
.)

service_entry:
.(
    cmp #$fe : beq post_tube
	cmp #$09 : beq help
	cmp #$04 : beq star
	cmp #13 : beq rfs_init
	cmp #14 : beq rfs_bget
    rts

star:
	jmp starcommand

post_tube:
    pha : txa : pha : tya : pha

    ; Check for soft-boot
	lda #$fd : ldx #$00 : ldy #$ff
	jsr osbyte
	cpx #0
	beq skip_init

    ; If it's not a soft boot, we want to perform first-time initialisation

	; Check if shadow mode has been locked - if so, don't try to use it
	jsr check_if_locked
	bcc skip_init

	; Continue initialisation
    jsr bootup

    lda #SCMD_INIT
    jsr shadow_command
skip_init:

    pla : tay : pla : tax : pla
    rts

help:
.(
	lda ($f2),y
	cmp #13
	bne skiphelp

	jsr nprintimm
	.byte 13, "SuperShadow V1X service ROM"
	.byte 13, "  SSON"
	.byte 13, "  SSOFF"
	.byte 13, 0

skiphelp:
	lda #9
	rts
.)


.(
&rfs_init:
	pha
	tya : eor #15 : cmp $f4 : bcc passon

	lda #<rfs_data : sta $f6
	lda #>rfs_data : sta $f7
	lda $f4 : eor #15 : sta $f5
	bpl claim

&rfs_bget:
	pha
	lda $f5 : eor #15 : cmp $f4 : bne passon
	ldy #0 : lda ($f6),y : tay
	inc $f6 : bne claim
	inc $f7

claim:
	pla : lda #0
	rts

passon:
	pla
	rts
.)

.)


; Returns with carry set if shadow mode is available, clear if it is locked
check_if_locked:
.(
	; These zero-page locations are corrupted by the test
	n_rts = $3f
	s_sec = $f8

	php : sei

	; Set up a "normal rts" stub
	lda #$60 : sta n_rts
	
	; Set up a fake "shadow sec" stub that doesn't set the carry
	sta s_sec

	; Set up the real "shadow sec" stub
	lda #$38    : sta $400+s_sec    ; sec
	lda #$4c    : sta $400+s_sec+1  ; jmp
	lda #<n_rts : sta $400+s_sec+2  ; <n_rts
	lda #>n_rts : sta $400+s_sec+3  ; >n_rts

	; Call it and check the carry flag
	clc
	jsr s_sec

	; Save the carry
	rol n_rts

	; Restore flags for interrupt state, restore carry, and exit
	plp
	ror n_rts
	rts
.)


starcommand:
.(
	; Taken from http://www.sprow.co.uk/bbc/library/sidewrom.pdf
	ldx #$ff : dey
	tya : pha

compare:
	iny : inx
	lda ($f2),y : and #$df : cmp table,x : beq compare

	lda table,x : bmi runnit

findnext:
	inx : lda table,x : bpl findnext

	inx
	pla : pha : tay
	jmp compare

table:
	.byte "SSON", >star_sson, <star_sson
	.byte "SSOFF", >star_ssoff, <star_ssoff
	.byte $ff

runnit:
	cmp #$ff : beq passon
	sta $f9
	inx : lda table,x
	sta $f8
	pla
	jmp ($f8)

passon:
	pla : tay
	lda #4
	rts

star_sson:
.(
	; Unlock shadow mode
	sei
	sta $e000 : sta $d000 : sta $e000 : sta $c000
	; Leave interrupts disabled for now

	; Boot up and initialise shadow OS
	jsr bootup

    ;jsr printimm
    ;.byte "Initialising shadow OS", 13, 13, 0

	jsr $ffe7

	; Send the initialisation command
	lda #SCMD_INIT
	jsr shadow_command

	; Chain to the post-Break handler to do the things that normally happen during reset -
	; hooking vectors with routines to pass them to Shadow mode, etc
	sec ; it only acts when the carry is set
	jsr normal_breakhandler

	; Issue a *DISC command so that DNFS reinitialises with its Tube support enabled
	ldx #<cmd_disc : ldy #>cmd_disc
	jsr do_oscli

	; Read currently-active language ROM number into X
	lda #$fc : ldx #0 : ldy #$ff : jsr osbyte

	; Reactivate the language ROM specified by X, causing it to get copied to shadow
	; RAM and executed there
	lda #$8e : jsr osbyte
	
    ; If it returns somehow, we can't really carry on as we've corrupted BASIC's 
	; zero page and set weird vectors, so reboot.
	jmp ($fffc)
	
cmd_disc:
	.byte "DISC", 13
.)

star_ssoff:
.(
	sei

	; Disable shadow mode
	sta $e000

	; Restore OS vectors
	lda $ffb8
	sta $f9
	lda $ffb7
	sta $f8
	ldy $ffb6
loop:
	dey
	lda ($f8),y : sta $0200,y
	cpy #0 : bne loop

	; Disable fake Tube
	lda #$ea : ldx #0 : ldy #0 : jsr $fff4

	; Disable BREAK intercept
	lda #247 : ldx #0 : ldy #0 : jsr $fff4

	cli

	jsr nprintimm
	.byte 13, "SuperShadow disabled", 13, 13, 0

	; Reactivate filing system
	ldx #<cmd_disc : ldy #>cmd_disc
	jsr do_oscli

	; Enter BASIC
	ldx #<cmd_basic : ldy #>cmd_basic
	jmp do_oscli

cmd_disc:
	.byte "DISC", 13

cmd_basic:
	.byte "B.", 13
.)

do_oscli:
.(
	stx $f8 : sty $f9
	ldy #0
loop:
	lda ($f8),y : sta $100,y
	cmp #13 : beq endloop
	iny : bne loop
endloop:
	ldx #<$100
	ldy #>$100
	jmp $fff7
.)

.)

