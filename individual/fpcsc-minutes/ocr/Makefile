# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

pdfs := $(shell find input -type f -iname '*.pdf' | sed 's/ /\\ /g')
pdfs_delim := $(shell find input -type f -iname '*.pdf' | tr '\n' '|')

.PHONY: all clean

all: output/fpcsc.parquet

clean: 
	-rm output/fpcsc.parquet*

output/fpcsc.parquet: \
		src/ocr.R \
		$(pdfs)
	Rscript --vanilla $< \
		--inputs="$(pdfs_delim)" \
		--xmldir=output/xml300 \
		--DPI=300 \
		--output=$@

# done.
