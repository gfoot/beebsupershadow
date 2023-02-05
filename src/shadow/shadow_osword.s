; OSWORDs have their parameter block copied into the transfer buffer before chaning to
; normal mode.  The A value is also saved.  After the call, the block in the transfer
; buffer has been updated, so we copy it back to the user's parameter block here.

oswordhandler:
.(
    ; OSWORD 00 needs special handling
    cmp #$00 : beq osword00handler

    ; Push the OSWORD number to the stack
    pha

    ; We'll be copying data from here in a bit
    stx srcptr
    sty srcptr+1

	tax

    ; Copy 16 bytes unless it's a high-numbered OSWORD
    ldy #16

    ; Check for high OSWORD number
    cmp #$80
    bcc copyparameterblock

    ; Read the actual number of parameters to send from the start of the block
    ldy #0
    lda (srcptr),y
    tay

copyparameterblock:
	dey
	lda (srcptr),y : sta shadow_transfer_buffer,y
	cpy #0 : bne copyparameterblock

	; Chain to normal mode to execute the OSWORD
	; OSWORD number is in X
    lda #CMD_OSWORD
    jsr normal_command

	; Copy the updated parameter block back to the user's original location
	; Default size is 16
	ldy #16

    ; Check for high OSWORD number
	pla : pha
    cmp #$80
    bcc copyparameterblockback

    ; Actual number of parameters to receive is the second byte of the block
    ldy #1
    lda shadow_transfer_buffer,y
    tay

copyparameterblockback:
	dey
	lda shadow_transfer_buffer,y : sta (srcptr),y
	cpy #0 : bne copyparameterblockback

    ; Restore the registers before returning to the caller
	ldx srcptr
	ldy srcptr+1
    pla
    rts
.)


osword00handler:
.(
    ; Copy the useful data out of the parameter block and put it on the stack
	; Also grab the user's buffer pointer and store it in destptr
    stx srcptr : sty srcptr+1
    ldy #4 : lda (srcptr),y : pha
    dey : lda (srcptr),y : pha
    dey : lda (srcptr),y : pha

	; Copy the user's buffer pointer into destptr
    dey : lda (srcptr),y : sta destptr+1
    dey : lda (srcptr),y : sta destptr
	
	; Put a normal-mode pointer to the transfer buffer on the stack instead
	lda #>normal_transfer_buffer : pha
	lda #<normal_transfer_buffer : pha    

    ; Call the normal-mode handler to read the line into the transfer buffer
    lda #CMD_OSWORD00
    jsr normal_command

	; Carry set means it was cancelled
	bcs return

	; Not cancelled, so copy the data to the user's buffer
	; Y = number of characters excluding the CR
	tya : tax

loop:
	lda shadow_transfer_buffer,y : sta (destptr),y
	dey : cpy #$ff : bne loop

	; Restore Y, clear carry again, and fall through to return
	txa : tay
	clc

return:
	; Remove the parameter block from the stack and return with carry preserved
	pla : pla : pla : pla : pla : rts
.)

