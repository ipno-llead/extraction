# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

input := ../import/output/minutes.parquet
regexes := hand/regexes.yaml
output := output/hrg-accused.parquet
src := src/accused.R

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): $(src) $(input) $(regexes)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(input) \
		--regexes=$(regexes) \
		--output=$@ &> output/log.txt

# done.
