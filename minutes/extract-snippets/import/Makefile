# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all clean

jsdir := output/jsonl

all: output/phase1.parquet output/phase2.parquet

clean: 
	-rm -r output/*

$(jsdir)/%/done.touch: input/%.zip
	-mkdir -p $(jsdir)/$*
	unzip input/$*.zip -d $(jsdir)/$*
	touch $@

output/%.parquet: src/import.R $(jsdir)/%/done.touch
	Rscript --vanilla $< \
		--inputdir=$(jsdir)/$* \
		--output=$@

# done.
