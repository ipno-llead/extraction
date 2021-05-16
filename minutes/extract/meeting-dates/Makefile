# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

input := ../import/output/minutes.parquet
output := output/mtg-dates.parquet
src := src/dates.R

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): $(src) $(input)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(input) \
		--output=$@

# done.
