; OSWORDs have their parameter block copied into the normal inbuffer before chaning to
; normal mode.  The A value is also saved.  After the call, the normal side copies the
; parameter block back automatically.  To facilitate this, the OSWORD number and parameter
; block address are pushed to the stack before calling normal mode.

oswordhandler:
.(
    ; OSWORD 00 needs special handling
    cmp #$00 : beq osword00handler

    ; Push the OSWORD number and parameter block address to the stack
    pha
    txa : pha
    tya : pha

    ; We'll be copying data from here in a bit
    stx srcptr
    sty srcptr+1

    ; Copy 16 bytes unless it's a high-numbered OSWORD
    ldy #16

    ; Restore the OSWORD number to check if it's high
    tsx : lda $0103,x

    cmp #$80
    bcc copyparameterblock

    ; Read the actual number of parameters to send from the start of the block
    ldy #0
    lda (srcptr),y
    tay

copyparameterblock:
    lda #<normal_inbuffer : sta destptr
    lda #>normal_inbuffer : sta destptr+1
    jsr copy_to_normal

    lda #CMD_OSWORD
    jsr normal_command

    ; Restore the registers before returning to the caller
    pla : tay
    pla : tax
    pla
    rts
.)

osword00handler:
    ; Copy the useful data out of the parameter block and put it on the stack
    stx srcptr : sty srcptr+1
    ldy #4 : lda (srcptr),y : pha
    dey : lda (srcptr),y : pha
    dey : lda (srcptr),y : pha
    dey : lda (srcptr),y : pha
    dey : lda (srcptr),y : pha
    
    ; Call the normal-mode handler, which will make its own parameter block, read the line
    ; and copy it to the target buffer based on this data
    lda #CMD_OSWORD00
    jsr normal_command

    ; Tidy up the stack
    pla : pla : pla : pla : pla
    rts


