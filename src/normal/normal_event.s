; Pass events through to the shadow OS

normal_eventhandler:
    jsr shadow_event
    jmp (normal_eventhandler_oldevntv)

normal_eventhandler_oldevntv:
    .word 0

