; Bootup code for Super Shadow RAM
;
; We start in N/N mode (normal read, normal write)
;
; Mode changes occur as a side effect of executing code in page zero.
;
; If A7 is set, then reads come from shadow memory.  If A6 is set then writes go to
; shadow memory.  Stack accesses always use shadow memory, so that portion of the
; normal memory is unused.
;
; Typically you want A6=A7 - i.e. execute some code in the range 00-3F, or C0-FF.  Then
; writes go to the same place that reads come from.  However, after startup we can't
; just switch to shadow mode because there's nothing in the RAM - so we need to transfer
; some boot code and other things to get things started.
;
; Thus the bootup code here, running in N/N mode, will switch to N/S mode - so that reads
; (including code) come from normal memory and writes go to shadow memory - and copy code 
; to the shadow RAM.
;
; Then it can switch to shadow mode and the code there takes control overall.
;
; Interrupts can be serviced in either mode.  Minimally, the shadow mode reflects them
; back into normal mode; but it'd also be possible to allow user code on the shadow side
; to intercept them and controls this process.  That would only make sense if the I/O
; regions were still active in shadow mode, which they're not at the moment.


+bootup:
.(
    ;jsr printimm
    ;.byte "SuperShadow starting", 13, 0

	; Relocate the long-term normal mode host code into the language workspace
	ldy #0
loop3:
	lda lang_ws_source,y : sta lang_ws_dest,y
	lda lang_ws_source+$100,y : sta lang_ws_dest+$100,y
	lda lang_ws_source+$200,y : sta lang_ws_dest+$200,y
	lda lang_ws_source+$300,y : sta lang_ws_dest+$300,y
	iny
	bne loop3

    ;jsr printimm
    ;.byte "Installing normal stubs", 13, 0

	; Copy the normal mode entry points into zero page, so that 
	; shadow code can use them to trigger normal code to run
	ldy #normal_stubs_size
	dey
loop:
	lda normal_stubs_source,y
	sta normal_stubs_dest,y
	dey
	bpl loop

	; Set up the "normal read, shadow write" stub, containing an RTS instruction
	lda #$60
	sta `normal_read_shadow_write

    ;jsr printimm
    ;.byte "Installing shadow stubs", 13, 0

	; Copy the shadow stubs into shadow zero page ready for use
	lda #<shadow_stubs_source : sta srcptr
	lda #>shadow_stubs_source : sta srcptr+1
	lda #<shadow_stubs_dest : sta destptr
	lda #>shadow_stubs_dest : sta destptr+1
	ldy #shadow_stubs_size
	jsr copy_to_shadow

    ;jsr printimm
    ;.byte "Uploading shadow OS ", 13, 0

	; Copy the main shadow code image to shadow memory
	lda #<shadow_code_source : sta srcptr
	lda #>shadow_code_source : sta srcptr+1
	lda #<shadow_code_dest : sta destptr
	lda #>shadow_code_dest : sta destptr+1

	ldx #>(shadow_code_size+255)
	ldy #<shadow_code_size

loop2:
	jsr copy_to_shadow
	inc srcptr+1 : inc destptr+1	
	iny ; to 0 which means 256 bytes
	dex : bne loop2

	; Install our reset intercept, to automatically reenable things when Break is pressed
	lda #248 : ldy #0 : ldx #<normal_breakhandler
	jsr $fff4
	lda #249 : ldy #0 : ldx #>normal_breakhandler
	jsr $fff4
	lda #247 : ldy #0 : ldx #$4c
	jsr $fff4

	rts
.)

