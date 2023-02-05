SOURCES = $(wildcard src/*.s) $(wildcard src/*/*.s)

all: bin/SUPSHAD bin/SUPSHAD.inf bin/supershadow.rom dnfs/supdnfs.rom bin/SSTEST

TARG = ../serial/serialfs/storage/DEFAULT

DEPLOYS = $(TARG)/SSTEST $(TARG)/SSTEST.inf
DEPLOYS += $(TARG)/SSTESTX $(TARG)/SSTESTX.inf
DEPLOYS += $(TARG)/SUPSHAD $(TARG)/SUPSHAD.inf

deploy: $(DEPLOYS)


bin/SUPSHAD labels/supshad.labels: $(SOURCES)
	xa -o bin/SUPSHAD src/main.s -I src -DSTANDALONE -l labels/supshad.labels

bin/SUPSHAD.inf: py/writeinf.py py/parsesyms.py labels/supshad.labels
	python py/writeinf.py labels/supshad.labels $@

bin/supershadow.rom labels/supershadow.rom.labels: $(SOURCES)
	xa -o bin/supershadow.rom src/main.s -I src -l labels/supershadow.rom.labels

dnfs/supdnfs.rom: dnfs/patch_dnfs.py dnfs/dnfs.rom
	(cd dnfs && python patch_dnfs.py)


bin/SSTEST: testsrc/test.s
	xa -o $@ $<

$(TARG)/% : bin/%
	cp $< $@

bin/SSTESTX: testsrc/test1x.s
	xa -o $@ $<
