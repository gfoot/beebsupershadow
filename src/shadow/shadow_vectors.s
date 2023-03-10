
initvectors:
.(
    ldx #defaultvectors_size
loop:
    lda defaultvectors-1,x
    sta $01ff,x
    dex
    bne loop
&rts_statement:
    rts
.)

default_brk:
.(
	jsr osnewl
	ldy #1
loop:
	lda ($fd),y
	beq loopend
	jsr oswrch
	iny
	bne loop
loopend:
	jsr osnewl
loop2:
	jmp loop2
.)


defaultvectors:
    .word unsupported       ; userv
    .word default_brk
    .word unsupported       ; irq1v
    .word unsupported       ; irq2v
    .word clihandler
    .word shadow_osbyte
    .word oswordhandler
    .word normal_oswrch
    .word rdchhandler
    .word filehandler
    .word argshandler
    .word bgethandler
    .word normal_osbput
    .word gbpbhandler
    .word findhandler
    .word unsupported       ; fscv 
    .word rts_statement     ; evntv
    .word unsupported       ; uptv
    .word unsupported       ; netv
    .word unsupported       ; vduv
    .word unsupported       ; keyv
    .word unsupported       ; insv
    .word unsupported       ; remv
    .word unsupported       ; cnpv
    .word rts_statement     ; ind1v
    .word rts_statement     ; ind2v
    .word rts_statement     ; ind3v
defaultvectors_size = *-defaultvectors


&shadowos_top
    .dsb $ffb9-*, $00      ; pad to vectors
#print *-shadowos_top

;osrdrm:                     ; ffb9
    jmp osrdrmhandler

;vduchr:                     ; ffbc
    jmp vduchrhandler

;osevnt:                     ; ffbf
    jmp normal_osevnt

;gsinit:                     ; ffc2
    jmp unsupported

;gsread:                     ; ffc5
    jmp unsupported

;nvrdch:                     ; ffc8
    jmp rdchhandler

;nvwrch:                     ; ffcb
    jmp normal_oswrch

;osfind:                     ; ffce
    jmp (findv)

;osgbpb:                     ; ffd1
    jmp (gbpbv)

;osbput:                     ; ffd4
    jmp (bputv)

;osbget:                     ; ffd7
    jmp (bgetv)

;osargs:                     ; ffda
    jmp (argsv)

;osfile:                     ; ffdd
    jmp (filev)

;osrdch:                     ; ffe0
    jmp (rdchv)

;osasci:                     ; ffe3
    cmp #13
    bne oswrch
;osnewl:                     ; ffe7
    lda #10
    jsr oswrch
    lda #13

;oswrch:                     ; ffee
    jmp (wrchv)

;osword:                     ; fff1
    jmp (wordv)

;osbyte:                     ; fff4
    jmp (bytev)

;oscli:                      ; fff7
    jmp (cliv)

    .word normal_nmi        ; fffa
    .word resethandler      ; fffc
    .word irqhandler        ; fffe

