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



; Routine to switch into the special mode where reads come from normal memory but
; writes go to shadow memory.  It's stored at a magic address and just contains an RTS.
normal_read_shadow_write = $40



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

	; Set up the "normal read, shadow write" stub, containing an RTS instruction
	lda #$60
	sta normal_read_shadow_write

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
	
	; Launch the shadow code
	lda #$ff
	jmp shadow_entry
.)


; The following code is copied into the $C0-$FF region of shadow zero page, and
; provides various actions that normal mode code can trigger when switching to
; shadow mode
shadow_shadow_stubs:
	* = $bf
shadow_shadow_stubs_dest:

; Stay in shadow mode but write to normal memory
shadow_read_normal_write:
	rts

; Main shadow entry point from normal mode
; A = command code, X,Y = parameters
shadow_entry:
	jmp shadow_entry_impl

; Call an arbutrary routine in shadow RAM
; YYXX = address to call
shadow_call_yyxx:
	jmp shadow_call_yyxx_impl

; RTS into shadow mode
shadow_rts:
	rts

shadow_shadow_stubs_size = *-shadow_shadow_stubs_dest
	* = shadow_shadow_stubs_source + shadow_shadow_stubs_size


normal_stubs:
	* = $30
normal_stubs_dest:

; Perform OSWRCH
normal_oswrch:
	jsr &FFEE
	jmp shadow_rts

; Perform OSBYTE
normal_osbyte:
	jsr &FFF4
	jmp shadow_rts

; Perform some other command, selected by A, parameters in X and Y
normal_command:
	jmp normal_command_impl

; Call a normal routine at YYXX from a shadow routine
normal_call_yyxx:
	jmp normal_call_yyxx_impl

normal_rts:
	rts


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
.(
	; Copy Y bytes of data (up to 256, pass Y=0 for 256)
	; from normal memory pointed at by $00/$01
	; to shadow memory pointed at by $02/$03

	; This involves switching to an asymmetric mode (reads coming from normal memory,
	; writes going to shadow memory) so we disable interrupts and stub out the NMI
	; handler.  Note that the stack is exempt from this, which is important otherwise
	; NMIs would need more careful handling.

	; Disable normal interrupts
	php
	sei

	; Save the first byte of the existing NMI handler, and replace it with an RTI
	lda $0d00 : pha
	lda #$40 : sta $0d00

	; Switch to normal read, shadow write mode
	jsr normal_read_shadow_write

	dey
loop:
	lda ($00),y : sta ($02),y
	dey
	cpy #$ff
	bne loop

	; Disable shadow writing, returning to pure normal mode
	jsr normal_rts

	; Restore the NMI handler and flags and return to caller
	pla
	sta $0d00
	plp
	rts
.)


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
