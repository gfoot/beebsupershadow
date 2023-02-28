	* = $2000

osasci = $ffe3
osnewl = $ffe7
oswrch = $ffee
osbyte = $fff4
oscli = $fff7

entry:
.(
	jsr ssoff
	jmp init_fs_enter_language
.)

nprintimm:
	jmp printimm

print_ptr = $70

#include "src/common/ssoff.s"
#include "src/common/init_fs_enter_language.s"
#include "src/common/utils.s"

