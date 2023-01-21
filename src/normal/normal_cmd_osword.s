do_osword_impl:
.(
    ; The stack contains a return address, then the high and low bytes of the parameter
    ; block address, then the osword number

    ; Get osword number from the stack - it's 5 bytes deep
    tsx : lda $0105,x

    pha

    ; Execute the OSWORD using our copy of the buffer
    ldx #<normal_inbuffer
    ldy #>normal_inbuffer
    jsr osword

    ; Copy 16 bytes back to the caller unless it's a high-numbered OSWORD
    ldy #16

    pla
    bpl transfer_and_return

    ; For high-numbered OSWORDs the second byte of the block has the number of bytes to
    ; return
    ldy normal_inbuffer+1

transfer_and_return:
    ; Copy from our version of the parameter block
    lda #<normal_inbuffer : sta $00
    lda #>normal_inbuffer : sta $01

    ; The user's parameter block address in shadow memory is still on the stack, above
    ; our return address
    tsx
    lda $0104,x : sta $02
    lda $0103,x : sta $03
        
    ; Do the copy and return
    jsr copy_to_shadow
    jmp shadow_rts
.)

do_osword00_impl:
.(
    ; The stack contains - above our return address - a copy of the user's parameter block
    ; We will save their buffer address for later, replace it with our own, and do the OS
    ; call; then copy the data into their buffer at the end
    tsx
    lda $0103,x : pha
    lda $0104,x : pha
    lda #<normal_inbuffer : sta $0103,x
    lda #>normal_inbuffer : sta $0104,x

    lda #$00 : ldy #$01
    inx : inx : inx
    jsr osword

    bcs cancelled
    
    lda #<normal_inbuffer : sta $00
    lda #>normal_inbuffer : sta $01
    pla : sta $03
    pla : sta $02

    tya : pha

    iny ; copy the CR as well

    jsr copy_to_shadow

    pla : tay
    clc
    jmp shadow_rts

cancelled:
    pla : pla ; discard the user's buffer address which we pushed earlier
    jmp shadow_rts
.)


