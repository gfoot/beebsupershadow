; BRK handler for normal-mode BRKs
;
; Note that shadow-mode BRKs also trigger normal-mode BRKs as part of the handling,
; so we do see those too and need to cope with them.
;
; We want to reflect these to the shadow mode in case there's a language there that
; can process them, before offering them to normal-mode languages.
;
; The Tube Host does this through the sideways ROM service call, but this isn't in 
; a ROM yet, so I'm doing it via BRKV which will point here.
; 
; We need to copy the error number and message to shadow memory.  The stack is an
; easy place to do that, but note that it's possible that the message is already
; on the stack as some sideways ROMs use it for a similar purpose.

normal_brkhandler:
.(
	; At this point FD/FE point at the error number - see if it's on the stack
	ldy $fe
	cpy #1
	bne copytostack

	; Point YYXX at the error code
	ldx $fd

	; Pass it to the shadow side
	jmp shadow_brk

copytostack:
	ldy #0
	sty $100 ; brk instruction
copyloop:
	lda ($fd),y : sta $101,y
	beq copyloopdone
	iny
	bne copyloop
copyloopdone:

	; Point YYXX at the error code
	ldy #1
	ldx #1

	; Pass it to the shadow side
	jmp shadow_brk
.)

