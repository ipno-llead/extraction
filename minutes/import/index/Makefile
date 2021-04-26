# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

dbtask := ../dl-dropbox
dbpath := extraction/minutes/import/dl-dropbox
indices := $(shell find $(dbtask)/output -iname 'index.csv')

wd := output/working
combind := $(wd)/index.parquet
out := output/metadata.csv

.PHONY: all clean

all: $(out)

clean: 
	-rm -r output/*

$(out): src/meta.R $(combind)
	Rscript --vanilla $< \
		--input=$(combind) \
		--dbpath=$(dbpath) \
		--output=$@

$(combind): src/combine-indices.R $(indices)
	-mkdir $(wd)
	Rscript --vanilla $< \
		--inputs="$(indices)" \
		--dbtask=$(dbtask) \
		--output=$@

# done.
