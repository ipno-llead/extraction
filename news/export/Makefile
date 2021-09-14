# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

news := ../import/export/output/news.parquet
uids := ../extract-entity-mentions/output/uid-matches.parquet
meta := ../import/export/output/metadata.csv

output := output/news-mentioned-entities.csv
src := src/export.R

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): $(src) $(news) $(uids) $(meta)
	-mkdir output
	Rscript --vanilla $< \
		--news=$(news) \
		--uids=$(uids) \
		--meta=$(meta) \
		--output=$@

# done.
