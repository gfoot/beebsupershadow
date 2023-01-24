

memtop = $e0       ; 2 bytes
srcptr = $f0       ; 2 bytes
destptr = $f2      ; 2 bytes
rdrmptr = $f6      ; 2 bytes
irq_save_a = $fc
brkptr = $fd       ; 2 bytes - part of OS API
escapeflag = $ff

print_ptr = srcptr

oshwm = $0800      ; BASIC isn't smart enough to deal with this being lower

