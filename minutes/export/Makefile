# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

hrgs := ../extract/export/output/hearings.parquet
meta := ../import/export/output/metadata.csv
docs := ../classify-pages/export/output/minutes.parquet

db_token := ../../share/creds/dropbox-auth-token.rds

pdf_index := output/pdf-index.parquet
txt_index := output/txt-index.parquet
db_index := output/db-index.parquet

wrgldir := ../../.wrgl
output := ../../output/documents.csv

.PHONY: all clean pdfs wrgl

all: wrgl

clean: 
	-rm -r output/*

wrgl: $(output)
	-wrgl init --wrgl-dir $(wrgldir)
	wrgl pull documents --wrgl-dir $(wrgldir) --depth 1
	cd $(dir $(wrgldir)) && wrgl commit documents "updated documents"
	wrgl push origin refs/heads/documents: --wrgl-dir $(wrgldir)

$(output): src/make-output.R $(db_index) $(hrgs)
	-mkdir -p $(shell dirname $@)
	Rscript --vanilla $< \
		--index=$(db_index) \
		--hearings=$(hrgs) \
		--output=$@

$(db_index): src/dropbox-up.R $(pdf_index) $(txt_index) $(db_token)
	Rscript --vanilla $< \
		--pdfindex=$(pdf_index) \
		--txtindex=$(txt_index) \
		--token=$(db_token) \
		--dbpath="/ppact/meeting-minutes-extraction/export" \
		--output=$@

$(txt_index): src/docs2txt.R $(docs)
	Rscript --vanilla $< \
		--docs=$(docs) \
		--outputdir=output

$(pdf_index): src/subset-pdfs.R $(hrgs) $(meta)
	Rscript --vanilla $< \
		--hrgs=$(hrgs) \
		--meta=$(meta) \
		--outputdir=output

# done.
