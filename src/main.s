; Main file pulling all the code into one binary

#include "constants.s"

#ifdef STANDALONE
#include "standalone.s"
#else
#include "romheader.s"
#endif

; The normal-mode code boots the system and services requests from the shadow code
#include "normal/normal.s"

; The stubs interface between the two modes
#include "normal_stubs.s"

; The shadow OS code presents the Acorn interface to language/user code and reflects the
; calls through to normal mode, along with interrupts
#include "shadow/shadow_os.s"

; Check some values make sense
#include "asserts.s"

rfs_data:
	.byte '+'

loadend:
