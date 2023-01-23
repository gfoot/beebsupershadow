import sys

from parsesyms import *


if len(sys.argv) != 3:
	print("Usage: %s <labelsfile> <inffile>")
	sys.exit(1)

labelspath, infpath = sys.argv[1:]

syms = parse_syms(labelspath)

loadaddr = get_unique_sym(syms, "loadaddr")
execaddr = get_unique_sym(syms, "execaddr")
host_mask = 0xffff0000

with open(infpath, "w") as fp:
	fp.write("$.SUPSHAD     %08X  %08X\n" % 
		(loadaddr | host_mask, execaddr | host_mask))
	fp.close()
