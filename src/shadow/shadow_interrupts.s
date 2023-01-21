
; Resets (e.g. Break being pressed) are just passed to normal mode
resethandler:
    lda #CMD_RESET
    jmp normal_command


; If a hardware interrupt occurs when in shadow mode, we just reflect it through to 
; normal mode; but BRK needs special handling in order to pass the error message etc
; to normal mode.
irqhandler:
    sta irq_save_a
    pla : pha
    and #$10
    bne brkhandler
    lda irq_save_a
    jmp normal_irq


; We need to capture the error number and error message that follows the BRK instruction,
; copy it to normal memory, and then let the normal mode BRK handler pass that to the OS
brkhandler:
.(
    tsx
    lda $0102,x
    sta srcptr
    lda $0103,x
    sta srcptr+1

    ; The first byte should be the error number, then the message - copy it all to the
    ; bottom of the stack page, with a BRK instruction first

    ldy #0
    sty $0100    
    lda (srcptr),y : sta $0101,y
loop:
    iny
    lda (srcptr),y : sta $0101,y
    bne loop

    ; Reset the stack and trigger a new BRK in normal mode
    ldx #$ff
    txs

    jmp normal_brk
.)

