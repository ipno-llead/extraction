# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

input := ../features/export/output/training-data-features.parquet
output := output/line-classifier.crfsuite
src := src/train-crf.R

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): $(src) $(input)
	Rscript --vanilla $< \
		--input=$(input) \
		--output=$@ &> output/training-log.txt

# done.
