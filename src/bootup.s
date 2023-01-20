; Bootup code for Super Shadow RAM
;
; We start in N/N mode (normal read, normal write)
;
; Mode changes occur as a side effect of executing code in page zero.
;
; If A7 is set, then reads come from shadow memory.  If A6 is set then writes go to
; shadow memory.
;
; Typically you want A6=A7 - i.e. execute some code in the range 00-3F, or C0-FF.  Then
; writes go to the same place that reads come from.  However, after startup we can't
; just switch to shadow mode because there's nothing in the RAM - so we need to transfer
; some boot code and other things to get things started.
;
; Thus the bootup code here, running in N/N mode, will switch to N/S mode - so that reads
; (including code) come from normal memory and writes go to shadow memory - and copy code 
; to the shadow RAM.



; Three bytes to store e.g. a "jmp" instruction in, which will switch to normal-write-shadow
; mode and jump to the chosen address.  The caller has to fill in the code here.
normal_write_shadow = $40



init:
.(
	; Copy the normal mode entry points into zero page, so that 
	; shadow code can use them to trigger normal code to run
	ldy #normal_stubs_size
	dey
loop:
	lda normal_stubs_source,y
	sta normal_stubs_dest,y
	dey
	bpl loop

	; Copy the shadow stubs into shadow zero page ready for use
	lda #<shadow_stubs_source : sta $0
	lda #>shadow_stubs_source : sta $1
	lda #<shadow_stubs_dest : sta $2
	lda #>shadow_stubs_dest : sta $3
	ldy #shadow_stubs_size
	jsr copy_to_shadow

	; Copy the main shadow code image to shadow memory
	lda #<shadow_code_source : sta $0
	lda #>shadow_code_source : sta $1
	lda #<shadow_code_dest : sta $2
	lda #>shadow_code_dest : sta $3

	ldx #>shadow_code_size
	ldy #<shadow_code_size

loop2:
	jsr copy_to_shadow
	inc $1 : inc $3	
	iny ; to 0
	dex : bpl loop2
	
	
	
.)


; The following code is copied into the $C0-$FF region of shadow zero page, and
; provides various actions that normal mode code can trigger when switching to
; shadow mode
shadow_shadow_stubs:
	* = $bf
shadow_shadow_stubs_dest:

; Stay in shadow mode but write to normal memory
shadow_write_normal:
	rts

; Main shadow entry point from normal mode
; A = command code, X,Y = parameters
shadow_entry:
	jmp shadow_call_yyxx_impl

; RTS into shadow mode
shadow_rts:
	rts

shadow_shadow_stubs_size = *-shadow_shadow_stubs_dest
	* = shadow_shadow_stubs_source + shadow_shadow_stubs_size


normal_stubs:
	* = $30
normal_stubs_dest:

	; Call a normal routine at YYXX from a shadow routine
normal_call_yyxx:
	jmp normal_call_yyxx_impl

normal_rts:
	rts
normal_end_copy_to_shadow:
	jmp end_copy_to_shadow


normal_normal_stubs_size = *-normal_normal_stubs_dest
	* = normal_normal_stubs_source + normal_normal_stubs_size


normal_call_yyxx_impl:
.(
	stx jsr_instr + 1
	sty jsr_instr + 2

jsr_instr:
	jsr $1234

	; Switch back to shadow mode and return
	jmp shadow_rts
.)


copy_to_shadow:
	; Copy Y bytes of data (up to 256, pass Y=0 for 256)
	; from normal memory pointed at by $00/$01
	; to shadow memory pointed at by $02/$03

	; We have to deal with NMIs
	;
	; This is a problem any time we are in an asymmetric mode because most code
	; won't function properly in this mode; and when an interrupt occurs the CPU 
	; will push the PC and flags to the wrong stack page, and even if we stub the
	; NMI handler with RTI, it will still read them back from the other stack page.
	;
	; A solution is to push our own desired return address and flags to *our* stack
	; before changing mode, and then pull them off again so that the values are 
	; still there below the stack pointer.  Now if an NMI occurs while we are in
	; the asymmetric mode, it will try to push a return address and flags as usual
	; but it will push them to the wrong stack; however then an RTI will read back 
	; *our* previously-stored values from our own stack, and we can clean up.
	;
	; Cleaning up probably means restarting the operation from scratch because we
	; have still lost track of how much progress was made - however it would also
	; be possible to write the code more carefully so it can resume.  For now 
	; though let's just write it so it can be restarted easily.

	; Disable normal interrupts, because we can do that at least
	php
	sei

	; Save the first bytes of the existing NMI handler, and replace it with an RTI
	lda $0d00 : pha
	lda #$40 : sta $0d00

	; Store the count in case we need to restart the operation
	sty $04

	; Remember the stack pointer
	tsx

	; Push the restart address and flags in case they're needed
	lda #>resume_copy_to_shadow : pha
	lda #<resume_copy_to_shadow : pha
	php

	; Restore the stack pointer to just above the things we pushed
	txs

	; Get ready to switch to normal read, shadow write mode, resuming execution at
	; resume_copy_to_shadow
	lda #$4c : sta normal_write_shadow                        ; jmp
	lda #<resume_copy_to_shadow : sta normal_write_shadow+1   ; address lo
	lda #>resume_copy_to_shadow : sta normal_write_shadow+2   ; address hi
	jmp normal_write_shadow

	; This is where we will restart from if necessary
resume_copy_to_shadow:
.(
	; Reload Y in case we restarted
	ldy $04

	dey
loop:
	lda ($00),y : sta ($02),y
	dey
	cpy #$ff
	bne loop

	; Disable shadow writing, restore the flags and return to caller.
	; jsr won't work here because it would write to the wrong stack,
	; so once again we have to jmp and jmp back
	jmp normal_end_copy_to_shadow
.)

end_copy_to_shadow:
	; Tidy up
	pla : sta $0d00
	plp
 	rts



shadow_code_source:
	* = $f800
shadow_code_dest:

shadow_call_yyxx_impl:
.(
	; Call a shadow routine at YYXX from a normal routine

	stx jsr_instr + 1
	sty jsr_instr + 2

jsr_instr:
	jsr $1234

	; Switch back to normal mode and return
	jmp normal_rts
.)

shadow_code_size = *-shadow_code_dest
