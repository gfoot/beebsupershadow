from parsesyms import *

def report(name, start, end):
	endaddr = None
	try:
		endaddr = int(end)
	except (ValueError, TypeError):
		if end:
			endaddr = get_unique_sym(syms, end)
	
	startaddr = get_unique_sym(syms, start)

	if end is not None:
		print("% 25s  %04x - %04x" % (name, startaddr, endaddr-1))
	else:
		print("% 25s  %04x" % (name, startaddr))

syms = parse_syms("labels/supshad.labels")

report("Normal stubs", "normal_stubs_dest", "normal_stubs_end")
report("Normal lang w/s code", "lang_ws_dest", "lang_ws_end")
report("Normal inbuffer", "normal_inbuffer", None)

print("")

report("Shadow stubs", "shadow_stubs_dest", "shadow_stubs_end")
report("Shadow ZP vars", "shadow_zpvars", 0x100)
report("Shadow inbuffer", "shadow_inbuffer", None)
report("Shadow OS Low", "shadow_os_low_dest", "shadow_os_low_end")
report("Shadow OS High", "shadow_os_high_dest", "shadow_os_high_end")

