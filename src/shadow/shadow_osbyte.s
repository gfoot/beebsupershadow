; Intercept some OSBYTEs, pass others on to the normal OS

shadow_osbyte:
.(
    cmp #$83 : beq shadow_osbyte83
    cmp #$84 : beq shadow_osbyte84
    jmp normal_osbyte

shadow_osbyte83:
    ldx #<oshwm
    ldy #>oshwm
    rts

shadow_osbyte84:
    ldx #<memtop
    ldy #>memtop
    rts
.)

