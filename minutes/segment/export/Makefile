# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

input := ../classify/output/minutes.parquet
output := output/minutes.parquet
src := src/assign-ids.R

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): $(src) $(input)
	Rscript --vanilla $< \
		--input=$(input) \
		--output=$@ &> output/log.txt

# done.
