SOURCES = $(wildcard src/*.s) $(wildcard src/*/*.s)

all: bin/SUPSHAD bin/SUPSHAD.inf bin/supershadow.rom dnfs/supdnfs.rom bin/SSTEST

TARG = ../serial/serialfs/storage/DEFAULT

DEPLOYS = $(TARG)/SSTEST $(TARG)/SSTEST.inf
DEPLOYS += $(TARG)/SSTESTX $(TARG)/SSTESTX.inf
DEPLOYS += $(TARG)/SUPSHAD $(TARG)/SUPSHAD.inf
DEPLOYS += $(TARG)/SHATEST $(TARG)/SHATEST.inf
DEPLOYS += $(TARG)/SSOFF $(TARG)/SSOFF.inf

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
	echo '$$.SSTESTX     ffff2000 ffff2000' > $@.inf

bin/SHATEST: testsrc/shatest.s
	xa -o $@ $<
	echo '$$.SHATEST     00002000 00002000' > $@.inf

bin/SSOFF: testsrc/ssoff.s
	xa -o $@ $<
	echo '$$.SSOFF       ffff2000 ffff2000' > $@.inf

