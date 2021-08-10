# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

index := ../index/output/metadata.csv

.PHONY: all clean

all: output/news-txt.parquet

output/news-txt.parquet: src/ocr-txt.R $(index)
	-mkdir output
	Rscript --vanilla $< \
		--index=$(index) \
		--txtdir=output/txt300 \
		--DPI=300 \
		--output=$@

# done.
