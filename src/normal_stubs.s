
; The normal stubs are copied to $20-$7f and must not extend to $80 or beyond
normal_stubs_source:
	* = $20
normal_stubs_dest:

; Interrupts

normal_brk:
    ; Retrigger the BRK in normal mode - the shadow BRK handler already copied the BRK 
    ; instruction and data to $0100
    jmp $0100

normal_irq:
    ; Allow the interrupt to retrigger in normal mode
    cli
	nop ; we need to idle here as the CPU won't process the interrupt immediately

    ; Switch back to shadow mode and return from the outer IRQ
    jmp shadow_rti

normal_nmi:
    ; NMIs can't be retriggered so need more effort
    jmp normal_nmi_impl


normal_oswrch:
    jmp normal_oswrch_impl

normal_osbyte:
    jmp normal_osbyte_impl

normal_osrdrm:
    jmp normal_osrdrm_impl

normal_osevnt:
    jmp normal_osevnt_impl

normal_osbput:
    jmp normal_osbput_impl

; Perform some other command, selected by A, parameters in X and Y
;
; This is used for lower-urgency commands and commands that require data marshalling in
; either direction
normal_command:
	jmp normal_command_impl


; Return into normal mode from shadow mode
normal_rts:
	rts

normal_stubs_end = *

normal_stubs_size = normal_stubs_end-normal_stubs_dest
	* = normal_stubs_source + normal_stubs_size
normal_stubs_source_end:

