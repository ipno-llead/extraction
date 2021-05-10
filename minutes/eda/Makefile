# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all clean

all: output/matched-entities-from-minutes.xlsx

clean: 
	-rm -r output/*

output/matched-entities-from-minutes.xlsx: \
		src/named-entities.R \
		input/minutes.parquet \
		input/index.csv \
		input/roster.csv
	-mkdir output
	Rscript --vanilla $< \
		--input=input/minutes.parquet \
		--index=input/index.csv \
		--roster=input/roster.csv \
		--tagger=frozen/english-ewt-ud-2.4-190531.udpipe \
		--output=$@ > output/named-entities-log.txt

# done.
