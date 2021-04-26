# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================
# extraction/individual/minutes/classify-pages/import/Makefile

text     := ../../import/export/output/minutes.parquet
meta     := ../../import/export/output/metadata.csv
labeldir := input/labeled-data

labels := $(shell find $(labeldir) -type f -iname '*.xlsx')
labs := output/labeled-data.parquet

.PHONY: all clean

all: output/minutes.parquet

clean: 
	-rm -r output/*

output/minutes.parquet: src/join-metadata.R $(text) $(meta) $(labs)
	-mkdir output
	Rscript --vanilla $< \
		--text=$(text) \
		--meta=$(meta) \
		--labs=$(labs) \
		--output=$@

$(labs): src/import-labels.R $(labels)
	-mkdir output
	Rscript --vanilla $< \
		--inputdir=$(labeldir) \
		--output=$@

# done.
