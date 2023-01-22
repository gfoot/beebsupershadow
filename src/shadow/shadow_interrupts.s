
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

    ; srcptr points at the error message; it's preceded by the error number and the BRK 
	; instruction.  Copy all of it to the bottom of the stack page

	; BRK instruction
    ldy #0
    sty $0100

	lda srcptr
	bne srcptrnotzero
	dec srcptr+1
srcptrnotzero:
	dec srcptr

	dey ; to $ff
loop:
    iny ; 0, 1, 2, etc
    lda (srcptr),y : sta $0101,y
    bne loop

    ; Reset the stack and trigger a new BRK in normal mode
    ldx #$ff
    txs

    jmp normal_brk
.)


; This one's a bit different - all BRKs are routed through normal mode, but if we started
; a language already then they are forwarded back here again.
;
; YYXX points at the error code, which will be on the stack, followed by the error 
; message.  All we do is store it at $fd/$fe where BASIC expects it, and chain to 
; its brk handler.
&shadow_brkhandler_impl:
.(
	stx brkptr
	sty brkptr+1
	jmp (brkv)
.)

