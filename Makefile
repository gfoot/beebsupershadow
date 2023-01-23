SOURCES = $(wildcard src/*.s) $(wildcard src/*/*.s)

all: bin/supshad.x bin/supshad.x.inf dnfs/supdnfs.rom


bin/supshad.x labels/supshad.labels: $(SOURCES)
	xa -o bin/supshad.x src/main.s -I src -l labels/supshad.labels

dnfs/supdnfs.rom: dnfs/patch_dnfs.py dnfs/dnfs.rom
	(cd dnfs && python patch_dnfs.py)

bin/supshad.x.inf: py/writeinf.py py/parsesyms.py labels/supshad.labels
	python py/writeinf.py labels/supshad.labels $@

