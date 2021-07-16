# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

ml_lab := ../classify/output/line-labels.parquet
hr_lab := ../classify/output/heuristic-labels.parquet
mins   := ../import/output/minutes.parquet

output := output/summary.txt

src := src/compare.R

.PHONY: all clean

all: $(output)

$(output): $(src) $(ml_lab) $(hr_lab) $(mins)
	-mkdir output
	Rscript --vanilla $< \
		--ml_lab=$(ml_lab) \
		--hr_lab=$(hr_lab) \
		--minutes=$(mins) \
		--output=$@

# done.
