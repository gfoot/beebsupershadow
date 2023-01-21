; Command dispatch for complex operations
&normal_command_impl:
.(
    cmp #CMD_OSWORD   : beq do_osword
    cmp #CMD_OSWORD00 : beq do_osword00
    cmp #CMD_BGET     : beq do_bget
    cmp #CMD_RDCH     : beq do_rdch
    cmp #CMD_VDUCHR   : beq do_vduchr
    cmp #CMD_RESET    : beq do_reset
    cmp #CMD_INIT     : beq do_init
    cmp #CMD_CALL     : beq do_call
    cmp #CMD_CLI      : beq do_cli
    cmp #CMD_FILE     : beq do_file
    cmp #CMD_ARGS     : beq do_args
    cmp #CMD_GBPB     : beq do_gbpb
    cmp #CMD_FIND     : beq do_find
    cmp #CMD_FSC      : beq do_fsc
    
    brk
    .db $fa, "Unknown command", 0

do_osword:
    jmp do_osword_impl

do_osword00:
    jmp do_osword00_impl

do_bget:
    jsr osbget
    jmp shadow_rts

do_rdch:
    jsr osrdch
    jmp shadow_rts

do_vduchr:
    jsr vduchr
    jmp shadow_rts

do_reset:
    jmp ($fffc)

do_init:
    jmp init

do_call:
.(
    stx jsr_instr+1
    sty jsr_instr+2
jsr_instr:
    jsr $1234
    jmp shadow_rts
.)

do_cli:
    ldx #<normal_inbuffer
    ldy #>normal_inbuffer
    jsr oscli
    jmp shadow_rts

do_file:
do_args:
do_gbpb:
do_find:
do_fsc:
    jmp unsupported
.)


; The rest bypass the command system above

&normal_oswrch_impl:
    jsr oswrch
    jmp shadow_rts

&normal_osbyte_impl:
    jsr osbyte
    jmp shadow_rts

&normal_osrdrm_impl:
    jsr osrdrm
    jmp shadow_rts

&normal_osevnt_impl:
    jsr osevnt
    jmp shadow_rts

&normal_osbput_impl:
    jsr osbput
    jmp shadow_rts

