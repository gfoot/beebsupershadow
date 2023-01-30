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

