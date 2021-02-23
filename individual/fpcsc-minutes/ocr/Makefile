# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

pdfs := $(shell find input -type f -iname '*.pdf' | sed 's/ /\\ /g')
pdfs_delim := $(shell find input -type f -iname '*.pdf' | tr '\n' '|')

.PHONY: all clean

all: output/fpcsc.parquet

clean: 
	-rm output/fpcsc.parquet*

output/fpcsc.parquet: src/ocr-txt.R $(pdfs)
	-mkdir output
	Rscript --vanilla $< \
		--inputs="$(pdfs_delim)" \
		--txtdir=output/txt300 \
		--DPI=300 \
		--output=$@

# done.
