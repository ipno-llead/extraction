# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

ocr := ../ocr/output/minutes.parquet

.PHONY: all clean

all: output/sampled.pdf

clean: 
	-rm -r output/*

output/sampled.pdf: src/samp.R $(ocr)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(ocr) \
		--sampsize=15 \
		--outputdir=output


# done.
