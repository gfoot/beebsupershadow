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
report("Normal lang w/s code low", "lang_ws_dest", "lang_ws_low_end")
report("Normal lang w/s code high", "lang_ws_high_start", "lang_ws_end")
report("Normal transfer buffer", "normal_transfer_buffer", None)

print("")

report("Shadow stubs", "shadow_stubs_dest", "shadow_stubs_end")
report("Shadow ZP vars", "shadow_zpvars", 0x100)
report("Shadow transfer buffer", "shadow_transfer_buffer", None)
report("Shadow OS low", "shadow_code_low_dest", "shadow_code_low_top")
report("Shadow OS high", "shadow_code_high_dest", "shadowos_top")
report("Shadow vectors", "osrdrm", "shadow_code_high_dest_end")

print("")

report("Load addr", "loadaddr", "loadend")
report("Exec addr", "execaddr", None)
report("Bootup", "bootup_begin", "bootup_end")
report("Lang w/s source", "lang_ws_source", "lang_ws_source_end")
report("Shadow stubs source", "shadow_stubs_source", "shadow_stubs_source_end")
report("Normal stubs source", "normal_stubs_source", "normal_stubs_source_end")
report("Shadow OS source", "shadow_code_low_source", "shadow_code_high_source_end")

