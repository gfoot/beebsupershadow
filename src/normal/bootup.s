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



init:
#print init
.(
    jsr printimm
    .byte "SuperShadow starting", 13, 0

    jsr printimm
    .byte "Installing normal stubs", 13, 0

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

    jsr printimm
    .byte "Installing shadow stubs", 13, 0

	; Copy the shadow stubs into shadow zero page ready for use
	lda #<shadow_stubs_source : sta $0
	lda #>shadow_stubs_source : sta $1
	lda #<shadow_stubs_dest : sta $2
	lda #>shadow_stubs_dest : sta $3
	ldy #shadow_stubs_size
	jsr copy_to_shadow

    jsr printimm
    .byte "Uploading shadow OS ", 0

	; Copy the main shadow code image to shadow memory
	lda #<shadow_code_source : sta $0
	lda #>shadow_code_source : sta $1
	lda #<shadow_code_dest : sta $2
	lda #>shadow_code_dest : sta $3

	ldx #>(shadow_code_size+255)
	ldy #<shadow_code_size

loop2:
	jsr copy_to_shadow
	inc $1 : inc $3	
	iny ; to 0 which means 256 bytes
    lda #'.' : jsr oswrch
	dex : bne loop2

    jsr osnewl
	
	jsr printimm
	.byte "Loading language image ", 0

	lda #<language_filename : sta print_ptr
	lda #>language_filename : sta print_ptr+1
	jsr print

	jsr loadlanguage

	jsr getrelocaddress

	jsr printimm
	.byte "Uploading to shadow RAM at &", 0

	lda $7 : jsr printhex
	lda $6 : jsr printhex
	jsr osnewl

	jsr uploadlanguage

    jsr printimm
    .byte "Initialising shadow OS", 13, 0

	; Send the initialisation command
	lda #SCMD_INIT
	jsr shadow_command

	; Install the BRK handler here as we're about to enter a language
	lda #<normal_brkhandler : sta brkv
	lda #>normal_brkhandler : sta brkv+1

	lda #SCMD_ENTERLANG
	ldx $6
	ldy $7
	jsr shadow_command

    ; If it returns somehow, we can't really carry on as we've corrupted BASIC's 
	; zero page, so re-enter it to let it reinitialise everything
    ldx #<cmd_basic
    ldy #>cmd_basic
    jmp oscli

cmd_basic:
    .byte "BASIC", 13


loadlanguage:
.(
	lda #$ff
	ldx #<osfileparams
	ldy #>osfileparams
	jmp osfile

osfileparams:
	.word language_filename
	.word languageimg, 0 ; load address
	.word 0, 0
	.word 0, 0
	.word 0, 0
.)

language_filename:
	.byte "HIBAS3", 13, 0

languageimg = $3000


getrelocaddress:
.(
	; The default base address for a language ROM is $8000
	lda #$00 : sta $6
	lda #$80 : sta $7

	; Byte 6 bit 6 indicates whether the language has a relocation address
	lda #$20 : bit languageimg+6 : beq noreloc

	; Byte 7 is the offset to a zero byte before the copyright string
	; The copyright string is followed by another zero byte, and then
	; the relocation target address
	ldy languageimg+7
skiptonextzeroloop:
	iny : lda languageimg,y : bne skiptonextzeroloop
	iny ; skip the zero

	; Copy out the relocation address
	lda languageimg,y : sta $6
	lda languageimg+1,y : sta $7

noreloc:
	rts
.)


uploadlanguage:
.(
	lda #<languageimg : sta $0
	lda #>languageimg : sta $1
	lda $6 : sta $2
	lda $7 : sta $3

	ldx #$40
copyloop:
	ldy #0 : jsr copy_to_shadow
	inc $1 : inc $3
	dex : bne copyloop

	rts
.)


.)


normal_call_yyxx_impl:
.(
	stx jsr_instr + 1
	sty jsr_instr + 2

jsr_instr:
	jsr $1234

	; Switch back to shadow mode and return
	jmp shadow_rts
.)


