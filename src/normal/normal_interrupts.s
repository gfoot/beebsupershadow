; Interrupt reflection into normal mode
;
; We don't intercept IRQ1V etc in normal mode, this is just to allow shadow mode to pass
; the interrupts through

; IRQ and BRK are entirely handled in the stubs, by simply retriggering them.
;
; NMI needs more care as it can't be retriggered like that; we also have to not store 
; anything directly in memory, we can only use the stack.
;
; On entry the flags and shadow return address are on the stack.  The normal IRQ handlers
; expect flags and a normal return address, rather than a shadow address, so we can't 
; just chain to them and let them RTI at the end.  Rather than try to modify the existing 
; address, it is simpler to just write a new stack frame with the data we want in it, then
; the old one is still there for us to return from afterwards.

&normal_nmi_impl;
    pha ; because we'll modify it in a bit; it is restored in shadow_rtnmi
   
    ; Push a new stack frame with return address set to shadow_rtnmi
    lda #>shadow_rtnmi : pha
    lda #<shadow_rtnmi : pha
    php

    ; Chain to the regular handler
    jmp ($fffa)

