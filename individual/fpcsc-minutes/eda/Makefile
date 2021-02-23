# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all clean

all: output/matched-entities.parquet

clean: 
		-rm -r output/*

output/matched-entities.parquet: \
		src/named-entities.R \
		input/fpcsc.parquet \
		input/POST_PPRR_11-6-2020.csv input/POST_PPRR_2-3-2021.csv
	-mkdir output
	Rscript --vanilla $< \
		--input=input/fpcsc.parquet \
		--tagger=frozen/english-ewt-ud-2.4-190531.udpipe \
		--output=$@ > output/named-entities-log.txt

# done.
