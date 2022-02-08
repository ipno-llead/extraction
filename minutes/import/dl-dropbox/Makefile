# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

ebr_fpcsc_db_path := PPACT/data/East Baton Rouge/Data Collected/Baton Rouge Fire and Police Civil Service Commission/Meeting Records/Minutes
ebr_fpcsc_out_path := output/east_baton_rouge/fpcsc

mvil_pcsb_db_path := PPACT/data/St. Tammany/Data Collected/Mandeville/Mandeville Police Civil Service Board/Minutes
mvil_pcsb_out_path := output/mandeville/pcsb

knr_fpcsb_db_path := PPACT/data/Jefferson/Data Collected/Kenner/Kenner Fire and Police Civil Service Board
knr_fpcsb_out_path := output/kenner/fpcsb

wwgo_db_path := PPACT/data/Jefferson/Data Collected/Westwego/Westwego Fire and Police Civil Service Board
wwgo_out_path := output/westwego/fpcsb

viv_db_path := PPACT/data/Caddo Parish/Data Collected/Vivian/Vivian Town Council
viv_out_path := output/vivian/vtc

la_db_path := PPACT/data/Louisiana State/Data Collected/Louisiana State Police Commission/Data Collected/Minutes
la_out_path := output/louisiana_state/lspc

sldl_db_path := PPACT/data/St. Tammany/Data Collected/Slidell/Slidell Civil Service Board
sldl_out_path := output/slidell/scsb

ads_db_path := PPACT/data/West Baton Rouge/Data Collected/Addis/Addis Town Council/Meeting Minutes
ads_out_path := output/addis/atc

orl_db_path := PPACT/data/Orleans/Data Collected/New Orleans Civil Service Commission
orl_out_path := output/orleans/nocsc

lc_db_path := PPACT/data/Calcasieu Parish/Data Collected/Lake Charles Fire and Police Civil Service Board
lc_out_path := output/lake_charles/lcfpcsb

sulph_db_path := PPACT/data/Calcasieu Parish/Data Collected/Sulphur/Sulphur Fire and Police Civil Service Board
sulph_out_path := output/sulphur/sfpcsb

harhn_db_path := PPACT/data/Jefferson/Data Collected/Harahan/Harahan Fire and Police Civil Service Board
harhn_out_path := output/harahan/hfpcsb

crnc_db_path := PPACT/data/Lafayette Parish/Data Collected/Carencro Fire and Police Civil Service Board
crnc_out_path := output/carencro/cfpcsb

ygvl_db_path := PPACT/data/Lafayette Parish/Data Collected/Youngsville/Youngsville Civil Service Board
ygvl_out_path := output/youngsville/ycsb

brsd_db_path := PPACT/data/Lafayette Parish/Data Collected/Broussard FPCSB
brsd_out_path := output/broussard/bfpcsb

bsir_db_path := PPACT/data/Bossier Parish/Requested/Bossier Fire and Police Civil Service Board 
bsir_out_path := output/bossier/bfpcsb

shport_db_path := PPACT/data/Caddo Parish/Data Collected/Shreveport/Shreveport FPCSB
shport_out_path := output/shreveport/fpcsb

iberia_db_path := PPACT/data/Iberia Parish/Collected/Iberia SO/Minutes 
iberia_out_path := output/iberia/ipso

token := ../../../share/creds/dropbox-auth-token.rds

.PHONY: all clean

all: \
	$(ebr_fpcsc_out_path)/index.csv \
	$(mvil_pcsb_out_path)/index.csv \
	$(knr_fpcsb_out_path)/index.csv \
	$(wwgo_out_path)/index.csv \
	$(viv_out_path)/index.csv \
	$(la_out_path)/index.csv \
	$(sldl_out_path)/index.csv \
	$(ads_out_path)/index.csv \
	$(orl_out_path)/index.csv \
	$(lc_out_path)/index.csv \
	$(sulph_out_path)/index.csv \
	$(harhn_out_path)/index.csv \
	$(crnc_out_path)/index.csv \
	$(ygvl_out_path)/index.csv \
	$(brsd_out_path)/index.csv \
	$(bsir_out_path)/index.csv \
	$(shport_out_path)/index.csv \
	$(iberia_out_path)/index.csv


$(orl_out_path)/index.csv: src/dl.R
	-mkdir -p $(orl_out_path)
	Rscript --vanilla $< \
		--path="$(orl_db_path)" \
		--token="$(token)" \
		--outdir="$(orl_out_path)"

$(ads_out_path)/index.csv: src/dl.R
	-mkdir -p $(ads_out_path)
	Rscript --vanilla $< \
		--path="$(ads_db_path)" \
		--token="$(token)" \
		--outdir="$(ads_out_path)"

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

$(lc_out_path)/index.csv: src/dl.R
	-mkdir -p $(lc_out_path)
	Rscript --vanilla $< \
		--path="$(lc_db_path)" \
		--token="$(token)" \
		--outdir="$(lc_out_path)"

$(sulph_out_path)/index.csv: src/dl.R
	-mkdir -p $(sulph_out_path)
	Rscript --vanilla $< \
		--path="$(sulph_db_path)" \
		--token="$(token)" \
		--outdir="$(sulph_out_path)"

$(harhn_out_path)/index.csv: src/dl.R
	-mkdir -p $(harhn_out_path)
	Rscript --vanilla $< \
		--path="$(harhn_db_path)" \
		--token="$(token)" \
		--outdir="$(harhn_out_path)"

$(crnc_out_path)/index.csv: src/dl.R
	-mkdir -p $(crnc_out_path)
	Rscript --vanilla $< \
		--path="$(crnc_db_path)" \
		--token="$(token)" \
		--outdir="$(crnc_out_path)"

$(ygvl_out_path)/index.csv: src/dl.R
	-mkdir -p $(ygvl_out_path)
	Rscript --vanilla $< \
		--path="$(ygvl_db_path)" \
		--token="$(token)" \
		--outdir="$(ygvl_out_path)"

$(brsd_out_path)/index.csv: src/dl.R
	-mkdir -p $(brsd_out_path)
	Rscript --vanilla $< \
		--path="$(brsd_db_path)" \
		--token="$(token)" \
		--outdir="$(brsd_out_path)"

$(bsir_out_path)/index.csv: src/dl.R
	-mkdir -p $(bsir_out_path)
	Rscript --vanilla $< \
		--path="$(bsir_db_path)" \
		--token="$(token)" \
		--outdir="$(bsir_out_path)"

$(shport_out_path)/index.csv: src/dl.R
	-mkdir -p $(shport_out_path)
	Rscript --vanilla $< \
		--path="$(shport_db_path)" \
		--token="$(token)" \
		--outdir="$(shport_out_path)"

$(iberia_out_path)/index.csv: src/dl.R
	-mkdir -p $(iberia_out_path)
	Rscript --vanilla $< \
		--path="$(iberia_db_path)" \
		--token="$(token)" \
		--outdir="$(iberia_out_path)"

# done.
