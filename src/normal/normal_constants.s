zpbuffer = $80         ; 4 bytes, used by OSARGS

print_ptr = zpbuffer

srcptr = zpbuffer      ; 2 bytes
destptr = zpbuffer+2   ; 2 bytes
transfersize = zpbuffer + 4

