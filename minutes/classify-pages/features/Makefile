# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

input := ../import/output/minutes.parquet
regex := hand/regexes.yaml

.PHONY: all clean

all: output/features.parquet

clean: 
	-rm -r output/*

output/features.parquet: src/mins-feats.R $(input) $(regex)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(input) \
		--regexes=$(regex) \
		--output=$@

# done.

