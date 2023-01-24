&shadow_event_impl:
.(
    jsr call_evntv
    jmp normal_rts
call_evntv:
    jmp (evntv)
.)

