# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

# vars {{{
mins_in := ../../classify-pages/export/output/minutes.parquet
mins_out := output/minutes.parquet

labs_dir := input/training-labels
labs := output/working/trainlabs.parquet
labs_fix := hand/label-fixes.yaml

train_out := output/training-data.parquet

labfiles := $(shell find $(labs_dir) -type f -iname '*.xls*')
# }}}

.PHONY: all clean

all: $(mins_out) $(train_out)

clean: 
	-rm -r output/*

$(train_out): src/export-training.R $(mins_out) $(labs)
	Rscript --vanilla $< \
		--minutes=$(mins_out) \
		--labels=$(labs) \
		--output=$@

$(labs): src/gather-training.R $(labfiles) $(labs_fix)
	-mkdir -p output/working
	Rscript --vanilla $< \
		--traindir=$(labs_dir) \
		--fixes=$(labs_fix) \
		--output=$@ &> output/labels-log.txt

$(mins_out): src/docs2lines.R $(mins_in)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(mins_in) \
		--output=$@

# done.
