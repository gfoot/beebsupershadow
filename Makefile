SOURCES = $(wildcard src/*.s) $(wildcard src/*/*.s)


bin/supshad.x: $(SOURCES)
	@xa -o $@ src/main.s -I src -l labels/supshad.labels

