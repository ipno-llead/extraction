# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

docs := ../import/output/minutes.parquet
labs := ../classify/output/line-labels.parquet
output := output/minutes.parquet
src := src/assign-ids.R

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): $(src) $(docs) $(labs)
	Rscript --vanilla $< \
		--docs=$(docs) \
		--labs=$(labs) \
		--output=$@ &> output/log.txt

# done.
