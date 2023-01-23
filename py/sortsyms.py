import re

lineparse = re.compile(r' *([^,]*), *([^,]*), *(.*)')

syms = []

with open("labels/supshad.labels", "r") as fp:
    for line in fp.readlines():
        m = lineparse.match(line.strip())
        assert m
        sym,addr,rest = m.groups()
        syms.append((addr,sym,rest))

for addr,sym,rest in sorted(syms):
    print("%s, %s, %s" % (addr,sym,rest))
