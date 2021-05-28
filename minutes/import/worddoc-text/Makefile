# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

input := ../index/output/metadata.csv
output := output/minutes-word.parquet
src := src/docx2txt.R

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
