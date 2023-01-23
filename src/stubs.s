; The following code is copied into the $C0-$FF region of shadow zero page, and
; provides various actions that normal mode code can trigger when switching to
; shadow mode
shadow_stubs_source:
    * = $bd
shadow_stubs_dest:

; Flag to say whether we're in shadow-read-normal-write mode - set it to $80
; before entering the mode
shadow_read_normal_write_flag:
    .byte 0

; Stay in shadow mode but write to normal memory
shadow_read_normal_write:
	rts

; Same but with rti
shadow_read_normal_write_rti:
    rti

; The address at this point should be $C0

; Main shadow entry point from normal mode
; A = command code, X,Y = parameters
shadow_command:
	jmp shadow_command_impl

; Exit from shadow-read-normal-write mode
shadow_read_normal_write_off:
    asl shadow_read_normal_write_flag
; RTS into shadow mode
shadow_rts:
	rts

; RTI from NMI to shadow mode - we need to pull A from the stack before returning
; and maybe actually return into shadow-read-normal-write mode
shadow_rtnmi:
    pla
    bit shadow_read_normal_write_flag
    bmi shadow_read_normal_write_rti
; RTI into shadow mode
shadow_rti:
    rti

; Execute shadow BRKV
shadow_brk:
	jmp shadow_brkhandler_impl

; Data transfers - set address
shadow_data_setaddr:
	jmp shadow_data_setaddr_impl

; Data transfers - read or write a byte
shadow_data_byte:
	jmp shadow_data_byte_impl

shadow_stubs_size = *-shadow_stubs_dest
* = shadow_stubs_source + shadow_stubs_size


; The normal stubs are copied to $20-$3f and must not extend to $40 or beyond
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


normal_stubs_size = *-normal_stubs_dest
	* = normal_stubs_source + normal_stubs_size


; Routine to switch into the special mode where reads come from normal memory but
; writes go to shadow memory.  It just contains an RTS (initialized on bootup).
normal_read_shadow_write = $40



