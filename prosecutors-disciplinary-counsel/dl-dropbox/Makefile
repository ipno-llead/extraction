# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

db_path := PPACT/data/Louisiana State/Data Collected/Louisiana Attorney Disciplinary Counsel
out_path := output/la-disc

token := ../../share/creds/dropbox-auth-token.rds

.PHONY: all clean

all: $(out_path)/index.csv

$(out_path)/index.csv: src/dl.R
	-mkdir -p $(out_path)
	Rscript --vanilla $< \
		--path="$(db_path)" \
		--token="$(token)" \
		--outdir="$(out_path)"

# done.
