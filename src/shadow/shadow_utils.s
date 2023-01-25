scanhex:
.(
    ldx #$00 : stx destptr : stx destptr+1
loop:
    lda (srcptr),y
    cmp #$30 : bcc return
    cmp #$3a : bcc number
    and #$df : sbc #7 : bcc return
    cmp #$40 : bcs return
number:
    asl : asl : asl : asl
    ldx #3
rolloop:
    asl : rol destptr : rol destptr+1
    dex : bpl rolloop
    iny : bne loop
return:
    rts
.)

skipspaces_skipone:
    iny
skipspaces:
    lda (srcptr),y : cmp #' ' : beq skipspaces_skipone
    rts

