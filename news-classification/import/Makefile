# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all clean

all: output/labeled-articles.parquet

clean: 
	-rm -r output/*

output/labeled-articles.parquet: src/import-join-prod.R
	-mkdir output
	Rscript $<
	
# done.
