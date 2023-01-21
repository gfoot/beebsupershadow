shadow_init:
.(
    jsr initvectors

    jsr printimm
    .byte "Shadow OS prototype active", 13, 0

    jsr shadow_test

    jmp normal_rts
.)

