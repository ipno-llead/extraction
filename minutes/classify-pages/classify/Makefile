# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

.PHONY: all clean

input := ../features/output/features.parquet
output := output/pagetypes.parquet

all: $(output)

clean: 
	-rm -r output/*

$(output): src/heuristic.R $(input)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(input) \
		--output=$@

# done.
