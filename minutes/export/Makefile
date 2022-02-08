# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

hrgs := ../extract/export/output/hearings.parquet
meta := ../import/export/output/metadata.csv
docs := ../classify-pages/export/output/minutes.parquet
wordtxt := ../import/worddoc-text/output/minutes-word.parquet

db_token := ../../share/creds/dropbox-auth-token.rds

pdf_index := output/pdf-index.parquet
txt_index := output/txt-index.parquet
db_index := output/db-index.parquet

wrgldir := output/documents
output := $(wrgldir)/documents.csv

.PHONY: all clean pdfs wrgl

all: wrgl

clean: 
	-rm -r output/*

wrgl: $(output)
	-wrgl init --wrgl-dir $(wrgldir)
	-wrgl remote add origin https://hub.wrgl.co/api/users/ipno/repos/documents --wrgl-dir $(wrgldir)
	wrgl pull main origin refs/heads/main:refs/heads/main --set-upstream --wrgl-dir $(wrgldir)
	wrgl commit main $(output) "updated documents" -p "docid,hrg_no,matched_uid,agency" --wrgl-dir $(wrgldir)
	wrgl push origin refs/heads/main:main --set-upstream --wrgl-dir $(wrgldir)

#wrgl: $(wrgl_creds) $(output)
#	set -o allexport ; source $(wrgl_creds) ; set +o allexport ;\
#	$(wrglctl) login --apikey=$$WRGL_APIKEY;
#	$(wrglctl) repos commit $(output) \
#		@ipno/documents \
#		"updated" \
#		-p "docid,hrg_no,matched_uid"

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
		--wordtxt=$(wordtxt) \
		--outputdir=output

# done.
