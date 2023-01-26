SOURCES = $(wildcard src/*.s) $(wildcard src/*/*.s)

all: bin/supshad.x bin/supshad.x.inf bin/supershadow.rom dnfs/supdnfs.rom


bin/supshad.x labels/supshad.labels: $(SOURCES)
	xa -o bin/supshad.x src/main.s -I src -DSTANDALONE -l labels/supshad.labels

bin/supshad.x.inf: py/writeinf.py py/parsesyms.py labels/supshad.labels
	python py/writeinf.py labels/supshad.labels $@

bin/supershadow.rom labels/supershadow.rom.labels: $(SOURCES)
	xa -o bin/supershadow.rom src/main.s -I src -l labels/supershadow.rom.labels

dnfs/supdnfs.rom: dnfs/patch_dnfs.py dnfs/dnfs.rom
	(cd dnfs && python patch_dnfs.py)


