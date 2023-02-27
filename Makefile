SOURCES = $(wildcard src/*.s) $(wildcard src/*/*.s)

TESTPROGS = SSTEST SSTESTX SSTEST2 SHATEST

PROGS = SUPSHAD SSOFF $(TESTPROGS)

INFS = $(addsuffix .inf,$(PROGS))

all: bin/supershadow.rom dnfs/supdnfs.rom $(addprefix bin/,$(PROGS) $(INFS))

TARG = ../serial/serialfs/storage/DEFAULT

DEPLOYS = $(addprefix $(TARG)/,$(PROGS) $(INFS))

deploy: $(DEPLOYS)


bin/SUPSHAD labels/supshad.labels: $(SOURCES)
	xa -o bin/SUPSHAD src/main.s -I src -DSTANDALONE -l labels/supshad.labels

bin/SUPSHAD.inf: py/writeinf.py py/parsesyms.py labels/supshad.labels
	python py/writeinf.py labels/supshad.labels $@

bin/supershadow.rom labels/supershadow.rom.labels: $(SOURCES)
	xa -o bin/supershadow.rom src/main.s -I src -l labels/supershadow.rom.labels

dnfs/supdnfs.rom: dnfs/patch_dnfs.py dnfs/dnfs.rom
	(cd dnfs && python patch_dnfs.py)


burn: bin/supershadow.rom
	minipro -p AT28C64B -w bin/supershadow.rom -s


$(TARG)/% : bin/%
	cp $< $@


bin/SSTEST: testsrc/test.s
	xa -o $@ $<
	echo '$$.SSTEST      ffff2000 ffff2000' > $@.inf

bin/SSTESTX: testsrc/test1x.s
	xa -o $@ $<
	echo '$$.SSTESTX     ffff2000 ffff2000' > $@.inf

bin/SSTEST2: testsrc/test2.s
	xa -o $@ $<
	echo '$$.SSTEST2     ffff2000 ffff2000' > $@.inf

bin/SHATEST: testsrc/shatest.s
	xa -o $@ $<
	echo '$$.SHATEST     00002000 00002000' > $@.inf

bin/SSOFF: testsrc/ssoff.s
	xa -o $@ $<
	echo '$$.SSOFF       ffff2000 ffff2000' > $@.inf

