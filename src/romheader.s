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
	cmp #$0d : beq rfs_init
	cmp #$0e : beq rfs_bget
    rts

post_tube:
    pha : txa : pha : tya : pha

    jsr bootup

	; If carry is set, bootup failed
	bcs skip_init

    ; Check for soft-boot
	lda #$fd : ldx #$00 : ldy #$ff
	jsr osbyte
	cpx #0
	beq skip_init

    ; If it's not a soft boot, we want to perform first-time initialisation
    lda #SCMD_INIT
    jsr shadow_command
skip_init:

    pla : tay : pla : tax : pla
    rts

rfs_init:
	jmp do_rfs_init

rfs_bget:
	jmp do_rfs_bget

help:
	lda ($f2),y
	cmp #13
	bne skiphelp

	jsr nprintimm
	.byte 13, "SuperShadow service ROM", 13
	.byte "  V2 hardware ", 0

	jsr detect_hardware
	bcc detected

	jsr nprintimm
	.byte "not ", 0

detected:
	jsr nprintimm
	.byte "present", 13, 0

skiphelp:
	lda #9
	rts

.)

.(
&do_rfs_init:
	pha
	tya : eor #15 : cmp $f4 : bcc passon

	lda #<rfs_data : sta $f6
	lda #>rfs_data : sta $f7
	lda $f4 : eor #15 : sta $f5
	bpl claim

&do_rfs_bget:
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

