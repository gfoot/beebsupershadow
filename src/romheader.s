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
	cmp #13
	beq rfs_init
	cmp #14
	beq rfs_bget
    rts

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

