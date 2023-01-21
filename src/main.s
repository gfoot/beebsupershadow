; Main file pulling all the code into one binary

; This is where this bootstrap code loads and executes in normal memory
* = $2000

#include "constants.s"

; The normal-mode code boots the system and services requests from the shadow code
#include "normal/normal.s"

; The stubs interface between the two modes
#include "stubs.s"

; The shadow OS code presents the Acorn interface to language/user code and reflects the
; calls through to normal mode, along with interrupts
#include "shadow/shadow_os.s"

