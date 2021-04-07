# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

minutes := ../import/output/minutes.parquet
outstub := output/sampled-20210407D
outputs := $(outstub).csv $(outstub).pdf
N := 10

.PHONY: all clean

all: $(outputs)

clean: 
	-rm -r output/*

$(outputs) &: src/sample-pages.R $(minutes)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(minutes) \
		--N=$(N) \
		--outstub=$(outstub)

# done.
