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
    cmp #$fe
    beq post_tube
    rts

post_tube:
    pha : txa : pha : tya : pha

    jsr bootup

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
.)

