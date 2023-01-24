; For non-bootup code loading, the Tube OS pushes the old program address, and restores 
; it if the command returns.  This causes HIMEM to get restored to its old value.
wrapped_entercode:
	lda memtop : pha
	lda memtop+1 : pha

	sec
	jsr entercode

	pla : sta memtop+1
	pla : sta memtop
	rts

; This is heavily based on the Tube OS's routine as documented by jgh at
; https://mdfs.net/Software/Tube/6502/Tube65v1.src
entercode:
.(
	; Push the flags for later - specifically we preserve C
	php

	; Record the address we're being asked to execute at
	stx srcptr
	sty srcptr+1

	; Based on the Tube OS - check for ROM header and verify it
	ldy #7 : lda (srcptr),y
	cld : clc : adc srcptr : sta brkptr
	lda #0 : adc srcptr+1 : sta brkptr+1

	; Check copyright string
	ldy #0 : ldx #3
checkcopyrightloop:
	lda (brkptr),y : cmp copyright,x : bne execute  ; if no copyright string, just run it
	iny : dex : bpl checkcopyrightloop

	; Check ROM type flags
	ldy #6 : lda (srcptr),y
	and #$4f : cmp #$40 : bcc notalanguage
	and #$0d : bne not6502code

execute:
	; X=$ff iff it's a language ROM; we want A=1 in that case or 0 otherwise
	lda #0 : inx : rol

	; If the code is in low memory, don't change memtop
	ldx srcptr : ldy srcptr+1 : bpl dontchangememtop

	; Update memtop, so that HIMEM is below the language ROM image
	stx memtop : sty memtop+1

	; The Tube OS sets a "current program address" as well, but that only seems 
	; necessary for the command prompt thing - at all other times this is identical to 
	; memtop.

dontchangememtop:

	; Restore flags from caller
	plp

	; A = 1 if launching a language ROM, 0 otherwise
	; XY points to code
	; C = 0 if entered as part of boot sequence, 1 otherwise
	jmp (srcptr)

copyright:
	.byte ")C(", 0

notalanguage:
    jsr initvectors
	brk : .byte 249, "This is not a language", 0

not6502code:
    jsr initvectors
	brk : .byte 249, "This is not 6502 code", 0
.)

