# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

# variables {{{
minutes := ../export/output/minutes.parquet
meta := ../../import/export/output/metadata.csv

outstub := targeted-20210705
exceldir := output/$(outstub)
docids := output/$(outstub)-docids.txt

#sampler := src/sample-docids.R
sampler := src/target-unlabeled-hearings.R
sampsize := 15
formatter := src/format-for-review.R

index := output/$(outstub)-index.xlsx
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
		--traindir=$(exceldir) \
		--output=$@

$(docids): $(sampler) $(minutes)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(minutes) \
		--already=frozen \
		--overweight=3 \
		--sampsize=$(sampsize) \
		--output=$@

# done.
