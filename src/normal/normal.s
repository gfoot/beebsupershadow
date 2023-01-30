; Code that runs in normal mode

.(

#include "normal/normal_constants.s"

&bootup_begin:
; Startup code comes first - this is no longer needed after the language boots
.(
#include "normal/bootup.s"
#include "common/utils.s"
.)
&bootup_end:

; Remaining code needs to be relocated into the language workspace, as memory above OSHWM could get 
; corrupted by other programs (e.g. *COPY)
lang_ws_source:
	* = $400
lang_ws_dest:

#include "normal/normal_entrypoints.s"

#include "normal/copytoshadow.s"
#include "normal/copyfromshadow.s"
#include "normal/normal_interrupts.s"
#include "normal/normal_command.s"
#include "normal/normal_cmd_osword.s"
#include "normal/normal_brk.s"
#include "normal/normal_breakhandler.s"
#include "normal/normal_event.s"

&lang_ws_end:

lang_ws_size = lang_ws_end-lang_ws_dest
	* = lang_ws_source + lang_ws_size
&lang_ws_source_end:

.)

