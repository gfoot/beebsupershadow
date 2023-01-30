; Bootup code for Super Shadow RAM
;
; We start in N/N mode (normal read, normal write)
;
; Mode changes occur as a side effect of executing code in page zero.
;
; If A7 is set, then shadow memory is enabled, otherwise it is disabled.  When
; shadow memory is enabled all read and write operations use shadow memory.
; When it is disabled the usual Beeb memory map applies, except that the stack 
; page is always in shadow memory, and the Tube I/O area at $fee0-$feff uses
; shadow memory in a special way.
;
; So to switch into shadow mode you need to execute some code at $80-$ff.  The
; code itself needs to be in shadow memory already as that's where the CPU
; will read from as soon as it tries to fetch an instruction from this range.
; And to switch back into normal mode you run some code between $00-$7f, which 
; will be read from normal memory.
;
; The bootup code here installs some trampolines in zero page to handle these
; transitions by immediately jumping to implementation code elsewhere in
; memory.  Thus the trampolines (which I also call stubs) are entry points
; into shadow mode from normal mode, and vice versa.
; 
; Once the stubs are set up, it uploads the Shadow OS code and passes over
; control to that.  Like with the Tube, the code running on the shadow side is
; the foreground task, and normal mode exists only to service I/O.
;
; Interrupts can be serviced in either mode.  Minimally, the shadow mode
; reflects them back into normal mode; but it'd also be possible to allow user
; code on the shadow side to intercept them and controls this process.  That
; would only make sense if the I/O regions were still active in shadow mode,
; which they're not at the moment.


+bootup:
.(
    ;jsr printimm
    ;.byte "SuperShadow starting", 13, 0

	; Attempt to detect presence of SuperShadow V2 hardware
	jsr detect_hardware
	bcc hardware_ok
	rts

hardware_ok:
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
.(
loop:
	lda normal_stubs_source,y
	sta normal_stubs_dest,y
	dey
	bpl loop
.)

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

	; Copy the low part of the shadow OS to shadow memory
	lda #<shadow_os_low_source : sta srcptr
	lda #>shadow_os_low_source : sta srcptr+1
	lda #<shadow_os_low_dest : sta destptr
	lda #>shadow_os_low_dest : sta destptr+1
	ldx #>(shadow_os_low_size+255)
	jsr copy_to_shadow_multipage

	; Copy the high part of the shadow OS to shadow memory
	lda #<shadow_os_high_source : sta srcptr
	lda #>shadow_os_high_source : sta srcptr+1
	lda #<shadow_os_high_dest : sta destptr
	lda #>shadow_os_high_dest : sta destptr+1
	ldx #>(shadow_os_high_size+255)
	jsr copy_to_shadow_multipage

	; Install our reset intercept, to automatically reenable things when Break is pressed
	lda #248 : ldy #0 : ldx #<normal_breakhandler
	jsr $fff4
	lda #249 : ldy #0 : ldx #>normal_breakhandler
	jsr $fff4
	lda #247 : ldy #0 : ldx #$4c
	jsr $fff4
	
	; Clear carry to indicate success
	clc
	rts


; Copy X whole pages to shadow memory
copy_to_shadow_multipage:
.(
	ldy #0

loop:
	jsr copy_to_shadow
	inc srcptr+1 : inc destptr+1	
	dex : bne loop

	rts
.)

.)

+detect_hardware:
.(
	pha
	lda #$03 : sta $feed : sta $feed
	lda #$2f : sta $fee5
	lda #$84 : sta $fee5
	lda #$03 : sta $feed : sta $feed
	lda $fee5 : cmp #$2f : bne nope
	lda $fee5 : cmp #$84 : bne nope
	lda #$03 : sta $feed : lda #$04 : sta $feed
	lda $fee5 : cmp #$84 : bne nope

	; Clear carry to indicate success
	clc
	pla
	rts

nope:
	; Set carry to indicate failure
	sec
	pla
	rts
.)

; Only call this if you're sure the ROM is paged in
+nprintimm:
	jmp printimm

