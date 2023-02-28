* = $2000
loadaddr:

; *RUN entry - strings together things that would happen at various different 
; stages in the ROM version
execaddr:
.(
	jsr sson
	jmp init_fs_enter_language
.)

#include "common/sson.s"
#include "common/init_fs_enter_language.s"

