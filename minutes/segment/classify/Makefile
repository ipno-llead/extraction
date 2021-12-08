# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

data    := ../features/export/output/minutes-features.parquet
model   := ../train/output/line-classifier.crfsuite
#crf_output := output/line-labels.parquet
truth   := ../import/output/training-data.parquet
hur_src := src/heuristic.R
crf_src := src/crf.R

hur_out := output/line-labels.parquet

.PHONY: all clean

all: $(hur_out)

clean: 
	-rm -r output/*

$(crf_output): $(crf_src) $(data) $(model)
	-mkdir output
	Rscript --vanilla $< \
		--data=$(data) \
		--model=$(model) \
		--truth=$(truth) \
		--output=$@ &> output/log.txt

$(hur_out): src/heuristic.R $(data)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(data) \
		--output=$@

# done.
