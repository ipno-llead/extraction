# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

# variables {{{
minutes := ../export/output/minutes.parquet
docids := output/sampled-docids.txt
meta := ../../import/export/output/metadata.csv

exceldir := output/training-data

sampler := src/sample-docids.R
formatter := src/format-for-review.R

index := output/training-data-index.xlsx
# }}}

.PHONY: all clean

all: $(index)

clean: 
	-rm -r output/*

$(index): $(formatter) $(minutes) $(meta) $(docids)
	-mkdir -p $(exceldir)
	Rscript --vanilla $< \
		--minutes=$(minutes) \
		--meta=$(meta) \
		--docs=$(docids) \
		--output=$@

$(docids): $(sampler) $(minutes)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(minutes) \
		--overweight=3 \
		--sampsize=40 \
		--output=$@

# done.
