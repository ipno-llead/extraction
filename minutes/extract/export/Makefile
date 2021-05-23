# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

input := ../merge/output/hearings.parquet
meta := ../import/output/metadata.csv
output := output/all-hearings.xlsx
src := src/doc2txt.R

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): $(src) $(input) $(meta)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(input) \
		--meta=$(meta) \
		--output=$@

# done.
