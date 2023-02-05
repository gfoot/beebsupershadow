; Bootup code for Super Shadow RAM
;
; We start in Normal mode where reads and writes come from normal beeb memory.
; We can switch into a shadow mode where they instead use shadow memory.
; 
; There are some exceptions - normal writes to $F800-$FFFF also write shadow memory, 
; and three memory regions are mapped to the same physical RAM between modes:
;
;       Shadow         Normal
;    $00C0-$00FF    $04C0-$04FF
;    $0100-$01FF    $0100-$01FF
;    $0300-$03FF    $0700-$07FF
;
; Mode changes occur as a side effect of executing code in page zero.
;
; If A7 is set, then shadow mode is activated; otherwise normal mode is activated.
;
; There's also a locking mechanism - writing to $Exxx while in normal mode will lock 
; the system in normal mode until consecutive writes occur to $Dxxx, $Exxx, and $Cxxx.
; While locked, executing code from zero page will have no effect on the active mode.
; Writing another address during the unlock sequence will cancel it.
;
; Our first job is to unlock shadow mode, and populate some areas of shadow RAM.  The
; shadow OS lives a $F800, and we also need to provide some entry points in shadow 
; zero page - trampolines that cause switches into shadow mode and execute shadow OS
; routines.
;
; We also need to provide similar trampolines for returning from shadow mode.
;
; In general once everything is set up we switch to shadow mode and let Shadow OS take
; over - the normal mode code then just stays resident to serve I/O requests from 
; shadow mode.
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
	; As this writes to $04C0-$04FF, this automatically installs the shadow stubs
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

    ;jsr printimm
    ;.byte "Uploading shadow OS", 13, 0

	; Copy the low shadow code image to shadow memory
	lda #<shadow_code_low_source : sta srcptr
	lda #>shadow_code_low_source : sta srcptr+1
	lda #<shadow_code_low_dest : sta destptr
	lda #>shadow_code_low_dest : sta destptr+1
	
	ldy #0
loop2a:
	lda (srcptr),y : sta (destptr),y
	iny : bne loop2a
	inc srcptr+1 : inc destptr+1	
	lda srcptr+1 : cmp #>shadow_code_low_source_end : bne loop2a

	; Copy the high shadow code image to shadow memory
	lda #<shadow_code_high_source : sta srcptr
	lda #>shadow_code_high_source : sta srcptr+1
	lda #<shadow_code_high_dest : sta destptr
	lda #>shadow_code_high_dest : sta destptr+1
	
	ldy #0
loop2b:
	lda (srcptr),y : sta (destptr),y
	iny : bne loop2b
	inc srcptr+1 : inc destptr+1	
	lda srcptr+1 : cmp #>shadow_code_high_source_end : bne loop2b


    ;jsr printimm
    ;.byte "Install BREAK handler", 13, 0

	; Install our reset intercept, to automatically reenable things when Break is pressed
	lda #248 : ldy #0 : ldx #<normal_breakhandler
	jsr $fff4
	lda #249 : ldy #0 : ldx #>normal_breakhandler
	jsr $fff4
	lda #247 : ldy #0 : ldx #$4c
	jsr $fff4

	rts
.)


; Only call this if you're sure the ROM is paged in
+nprintimm:
       jmp printimm


