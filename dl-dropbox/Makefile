# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

ebr_fpcsc_db_path := PPACT/data/East Baton Rouge/Data Collected/Baton Rouge Fire and Police Civil Service Commission/Meeting Records/Minutes
ebr_fpcsc_out_path := output/east-baton-rouge/fpcsc

mvil_pcsb_db_path := PPACT/data/St. Tammany/Data Collected/Mandeville/Mandeville Police Civil Service Board/Minutes
mvil_pcsb_out_path := output/mandeville/pcsb

knr_fpcsb_db_path := PPACT/data/Jefferson/Data Collected/Kenner/Kenner Fire and Police Civil Service Board
knr_fpcsb_out_path := output/kenner/fpcsb

wwgo_db_path := PPACT/data/Jefferson/Data Collected/Westwego/Westwego Fire and Police Civil Service Board
wwgo_out_path := output/westwego/fpcsb

viv_db_path := PPACT/data/Caddo Parish/Data Collected/Vivian/Vivian Town Council
viv_out_path := output/vivian/vtc

la_db_path := PPACT/data/Louisiana State/Louisiana State Police Commission/Data Collected/Minutes
la_out_path := output/louisiana_state/lspc

sldl_db_path := PPACT/data/St. Tammany/Data Collected/Slidell/Slidell Civil Service Board
sldl_out_path := output/slidell/scsb

token := frozen/auth-token.rds

.PHONY: all clean

all: \
	$(ebr_fpcsc_out_path)/index.csv \
	$(mvil_pcsb_out_path)/index.csv \
	$(knr_fpcsb_out_path)/index.csv \
	$(wwgo_out_path)/index.csv \
	$(viv_out_path)/index.csv \
	$(la_out_path)/index.csv \
	$(sldl_out_path)/index.csv

$(sldl_out_path)/index.csv: src/dl.R
	-mkdir -p $(sldl_out_path)
	Rscript --vanilla $< \
		--path="$(sldl_db_path)" \
		--token="$(token)" \
		--outdir="$(sldl_out_path)"

$(la_out_path)/index.csv: src/dl.R
	-mkdir -p $(la_out_path)
	Rscript --vanilla $< \
		--path="$(la_db_path)" \
		--token="$(token)" \
		--outdir="$(la_out_path)"

$(viv_out_path)/index.csv: src/dl.R
	-mkdir -p $(viv_out_path)
	Rscript --vanilla $< \
		--path="$(viv_db_path)" \
		--token="$(token)" \
		--outdir="$(viv_out_path)"

$(wwgo_out_path)/index.csv: src/dl.R
	-mkdir -p $(wwgo_out_path)
	Rscript --vanilla $< \
		--path="$(wwgo_db_path)" \
		--token="$(token)" \
		--outdir="$(wwgo_out_path)"


$(knr_fpcsb_out_path)/index.csv: src/dl.R
	-mkdir -p $(knr_fpcsb_out_path)
	Rscript --vanilla $< \
		--path="$(knr_fpcsb_db_path)" \
		--token="$(token)" \
		--outdir="$(knr_fpcsb_out_path)"


$(ebr_fpcsc_out_path)/index.csv: src/dl.R
	-mkdir -p $(ebr_fpcsc_out_path)
	Rscript --vanilla $< \
		--path="$(ebr_fpcsc_db_path)" \
		--token="$(token)" \
		--outdir="$(ebr_fpcsc_out_path)"

$(mvil_pcsb_out_path)/index.csv: src/dl.R
	-mkdir -p $(mvil_pcsb_out_path)
	Rscript --vanilla $< \
		--path="$(mvil_pcsb_db_path)" \
		--token="$(token)" \
		--outdir="$(mvil_pcsb_out_path)"

# done.
