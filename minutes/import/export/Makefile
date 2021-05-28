# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

pdf_mins := ../ocr/output/minutes-pdf.parquet
word_mins := ../worddoc-text/output/minutes-word.parquet
meta := ../index/output/metadata.csv

out_mins := output/minutes.parquet
out_meta := output/metadata.csv

.PHONY: all clean

all: $(out_mins) $(out_meta)

clean: 
		-rm -r output/*

$(out_mins): src/combine.R $(pdf_mins) $(word_mins)
	-mkdir output
	Rscript --vanilla $< \
		--pdf=$(pdf_mins) \
		--word=$(word_mins) \
		--output=$@

$(out_meta): $(meta)
	-mkdir output
	cd output && ln -s ../$< .

# done.
