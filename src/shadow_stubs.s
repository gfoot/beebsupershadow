; The following code is copied into the $C0-$FF region of shadow zero page, and
; provides various actions that normal mode code can trigger when switching to
; shadow mode
shadow_stubs_source:
    * = $c0
shadow_stubs_dest:

; Data transfers - read or write a byte
&shadow_data_byte:
	jmp shadow_data_byte_impl

; Main shadow entry point from normal mode
; A = command code, X,Y = parameters
&shadow_command:
	jmp shadow_command_impl

; RTS into shadow mode
shadow_rts:
	rts

; RTI from NMI to shadow mode - we need to pull A from the stack before returning
shadow_rtnmi:
    pla
; RTI into shadow mode
&shadow_rti:
    rti

; Execute shadow BRKV
shadow_brk:
	jmp shadow_brkhandler_impl

; Data transfers - set address
shadow_data_setaddr:
	jmp shadow_data_setaddr_impl

; Execute shadow EVNTV
shadow_event:
	jmp shadow_event_impl

&shadow_stubs_end = *

shadow_stubs_size = shadow_stubs_end-shadow_stubs_dest
* = shadow_stubs_source + shadow_stubs_size
shadow_stubs_source_end:

