# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================
# extraction/individual/minutes/classify-frontpages/import/Makefile

minutes := ../../ocr/output/minutes.parquet
labeldir := input/labeled-data

labels := $(shell find $(labeldir) -type f -iname '*.xlsx')

.PHONY: all clean

all: output/minutes.parquet output/labeled-data.parquet

clean: 
	-rm -r output/*

output/minutes.parquet: $(minutes)
	-mkdir output
	cd output && ln -s ../$(minutes) .

output/labeled-data.parquet: src/import-labels.R $(labels)
	-mkdir output
	Rscript --vanilla $< \
		--inputdir=$(labeldir) \
		--output=$@

# done.
