# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

dbtask := ../dl-dropbox
dbpath := extraction/news/import/dl-dropbox
index := $(shell find $(dbtask)/output -iname 'index.csv')

out := output/metadata.csv

.PHONY: all clean

all: $(out)

clean: 
	-rm -r output/*

$(out): src/meta.R $(combind)
	Rscript --vanilla $< \
		--input=$(index) \
		--dbpath=$(dbpath) \
		--output=$@

# done.
