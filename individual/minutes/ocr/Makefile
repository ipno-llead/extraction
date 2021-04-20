# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

indices := ../../../dl-dropbox/output/east-baton-rouge/fpcsc/index.csv \
	../../../dl-dropbox/output/kenner/fpcsb/index.csv \
	../../../dl-dropbox/output/louisiana_state/lspc/index.csv \
	../../../dl-dropbox/output/mandeville/pcsb/index.csv \
	../../../dl-dropbox/output/slidell/scsb/index.csv \
	../../../dl-dropbox/output/vivian/vtc/index.csv \
	../../../dl-dropbox/output/westwego/fpcsb/index.csv

.PHONY: all clean

all: output/minutes.parquet

output/index.csv: src/combine-indices.R $(indices)
	-mkdir output
	Rscript --vanilla $< \
		--inputs="$(indices)" \
		--output=$@

output/minutes.parquet: src/ocr-txt.R output/index.csv
	-mkdir output
	Rscript --vanilla $< \
		--index=output/index.csv \
		--txtdir=output/txt300 \
		--DPI=300 \
		--output=$@

# done.
