# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

minutes := ../import/output/minutes.parquet
meta := ../../import/export/output/metadata.csv
outstub := output/sampled-20210422
N := 10

.PHONY: all clean outputs

outputs := $(outstub).xlsx $(outstub).pdf

all: outputs

clean: 
	-rm -r output/*

%.xlsx %.pdf: src/sample-pages.R $(minutes)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(minutes) \
		--meta=$(meta) \
		--frozendir=frozen \
		--N=$(N) \
		--outstub=$*

# done.
