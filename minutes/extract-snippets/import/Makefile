# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all clean

hrgs := ../../extract/export/output/hearings.parquet

jsdir := output/jsonl
trndir := output/training

all: $(trndir)/phase1.parquet \
	$(trndir)/phase2.parquet \
	output/hrg-sentences.parquet \
	output/phase2-all-labels.parquet

clean: 
	-rm -r output/*

$(jsdir)/%/done.touch: input/%.zip
	-mkdir -p $(jsdir)/$*
	unzip input/$*.zip -d $(jsdir)/$*
	touch $@

$(trndir)/%.parquet: src/import.R $(jsdir)/%/done.touch
	-mkdir -p $(trndir)
	Rscript --vanilla $< \
		--inputdir=$(jsdir)/$* \
		--output=$@

output/hrg-sentences.parquet: src/prep-sents.R $(hrgs)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(hrgs) \
		--output=$@

output/%-all-labels.parquet: src/prep-labs.R output/training/%.parquet
	Rscript --vanilla $< \
		--input=output/training/$*.parquet \
		--output=$@

# done.
