	* = $2000

print_ptr = $40
osasci = $ffe3
oswrch = $ffee
osnewl = $ffe7
osword = $fff1
osbyte = $fff4

buffer = $1f00

shadow_test:
.(
    jsr printimm
    .byte "Testing OS calls from shadow code", 13, 0

	php : cli

    jsr osnewl

    jsr printimm
    .byte "OSWRCH clearly works", 13, 0

    jsr test_osbyte00
    jsr test_osbyte81
    jsr test_osbyte8384
    
    jsr test_osword00
    jsr test_osword01
    jsr test_osword07

	jsr test_pressspace

	plp
    rts


test_osword00:
.(
    jsr printimm
    .byte "OSWORD 00 - Type something: ", 0

    ldx #<osw00params
    ldy #>osw00params
    lda #0
    jsr osword

    bcs cancelled

    jsr printimm
    .byte "   You typed: ", 0

    lda osw00params : sta print_ptr
    lda osw00params+1 : sta print_ptr+1
    lda #0 : sta (print_ptr),y
    jsr print
    jmp osnewl

cancelled:
    jsr printimm
    .byte 13,"   Cancelled, did you press Escape?", 13, 0
	rts

osw00params:
    .word buffer
    .byte $40
    .byte 0,$ff
.)

test_osword01:
.(
    jsr printimm
    .byte "OSWORD 01 - TIME=&", 0

    ldx #<buffer
    ldy #>buffer
    lda #1
    jsr osword

    ldx #4
loop:
    lda buffer,x
    jsr printhex
    dex
    bpl loop
    
    jmp osnewl
.)

test_osword07:
.(
    jsr printimm
    .byte "OSWORD 07 - SOUND", 13, 0
    
    lda #7
    ldx #<osw07params
    ldy #>osw07params
    jmp $fff1

osw07params:
    .word 3,-15,50,5
.)

test_osbyte00:
.(
    jsr printimm
    .byte "OSBYTE 00 - Host/OS type: &", 0

    lda #0 : ldx #1
    jsr osbyte
    txa
    jsr printhex
    jmp osnewl
.)

test_osbyte81:
.(
    jsr printimm
    .byte "OSBYTE 81 - press a key, quick: ", 0

    lda #$81 : ldy #0 : ldx #100
    jsr osbyte

    bcs notpressed

    txa : jsr oswrch
    jmp next

notpressed:
    jsr printimm
    .byte "Too slow!", 0

next:
    jmp osnewl
.)

test_pressspace:
.(
    jsr printimm
    .byte 13, "   Press SPACE to continue...", 0

loop:
    lda #$81 : ldy #$ff : ldx #256-99
    jsr osbyte
    cpx #0
    beq loop

    jmp osnewl
.)

test_osbyte8384:
.(
    jsr printimm
    .byte "OSBYTE 83/84 - mem range: &", 0

    lda #$83 : jsr osbyte
    tya : jsr printhex
    txa : jsr printhex

    jsr printimm
    .byte " - &", 0

    lda #$84 : jsr osbyte
    tya : jsr printhex
    txa : jsr printhex

    jmp osnewl
.)

.)

#include "src/common/utils.s"

