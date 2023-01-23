SOURCES = $(wildcard src/*.s) $(wildcard src/*/*.s)


bin/supshad.x: $(SOURCES)
	@xa -o $@ src/main.s -I src -l labels/supshad.labels

dnfs/supdnfs.rom: dnfs/patch_dnfs.py dnfs/dnfs.rom
	@(cd dnfs && python patch_dnfs.py)

