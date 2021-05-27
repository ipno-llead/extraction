# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

hrgs := ../extract/export/output/hearings.parquet
meta := ../import/export/output/metadata.csv
docs := ../classify-pages/export/output/minutes.parquet

wrglctl := ../../share/bin/wrglctl
wrgl_creds := ../../share/creds/wrgl-creds.txt

db_token := ../../share/creds/dropbox-auth-token.rds

pdf_index := output/pdf-index.parquet
db_index := output/db-index.parquet

output := output/documents.csv

.PHONY: all clean pdfs wrgl

all: wrgl

clean: 
	-rm -r output/*

wrgl: $(wrgl_creds) $(output)
	set -o allexport; source $(wrgl_creds); set +o allexport
	$(wrglctl) login --apikey=${WRGL_APIKEY}
	$(wrglctl) repos commit $(output) \
		@ipno/documents \
		"updated" \
		-p "docid,hrg_no,matched_uid"

$(output): src/merge-doctxt.R $(db_index) $(hrgs) $(docs)
	Rscript --vanilla $< \
		--index=$(db_index) \
		--hearings=$(hrgs) \
		--docs=$(docs) \
		--output=$@

$(db_index): src/dropbox-up.R $(pdf_index) $(db_token)
	Rscript --vanilla $< \
		--index=$(pdf_index) \
		--token=$(db_token) \
		--dbpath="/ppact/meeting-minutes-extraction/export/pdfs" \
		--output=$@

$(pdf_index): src/subset-pdfs.R $(hrgs) $(meta)
	Rscript --vanilla $< \
		--hrgs=$(hrgs) \
		--meta=$(meta) \
		--outputdir=output

# done.
