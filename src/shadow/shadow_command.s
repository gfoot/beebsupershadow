; Main command entry point
;
; A = command code
; X,Y = parameters
&shadow_command_impl:
.(
    cmp #SCMD_INIT : beq do_init

    brk
    .db $fa, "Unknown command", 0

do_init:
    jmp shadow_init
.)


