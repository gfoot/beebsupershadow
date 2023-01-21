; Simple commands - these pass parameters and results in A, X, and Y alone, and don't
; require memory transfers

osrdrmhandler:
    ; Slight exception, this one uses an address in zero page which does need transferring
    ldx rdrmptr
    lda rdrmptr+1
    jmp normal_osrdrm

vduchrhandler:
    lda #CMD_VDUCHR
    jmp normal_command

rdchhandler:
    lda #CMD_RDCH
    jmp normal_command

bgethandler:
    lda #CMD_BGET
    jmp normal_command

&unsupported:
    brk
    .byte $fc, "Bad command", 0
