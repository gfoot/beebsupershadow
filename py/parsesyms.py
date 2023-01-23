import re

lineparse = re.compile(r' *([^,]*), *([^,]*), *([^,]*), *(.*)')

def parse_syms(path):
	syms = {}

	with open(path, "r") as fp:
		for line in fp.readlines():
			m = lineparse.match(line.strip())
			assert m
			sym,addr,scope,rest = m.groups()

			addr = int(addr, 16)
			scope = int(scope)

			if sym not in syms:
				syms[sym] = {}
			assert scope not in syms[sym]
			syms[sym][scope] = addr,rest

	return syms


def get_unique_sym(syms, name):
	entries = syms[name]
	assert len(entries) == 1
	for k,(addr,rest) in entries.items():
		return addr

