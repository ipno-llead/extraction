# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

ebr_fpcsc_db_path := PPACT/data/East Baton Rouge/Data Collected/Baton Rouge Fire and Police Civil Service Commission/Meeting Records/Minutes
ebr_fpcsc_out_path := output/east-baton-rouge/fpcsc
token := frozen/auth-token.rds

.PHONY: all clean

all: $(ebr_fpcsc_out_path)/index.csv

%/index.csv: src/dl.R
	-mkdir -p $*
	Rscript --vanilla $< \
		--path="$(ebr_fpcsc_db_path)" \
		--token="$(token)" \
		--outdir="$*"

# done.
