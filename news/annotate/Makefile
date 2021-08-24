# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

news := ../import/export/output/news.parquet

annotate := src/annotate-spacy.R
annotations := output/news-annotated.parquet

.PHONY: all clean

all: $(annotations)

clean: 
	-rm -r output/*

$(annotations): $(annotate) $(news)
	-mkdir $(shell dirname $@)
	Rscript --vanilla $< \
		--input=$(news) \
		--output=$@
	
# done.
