# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all clean

hrgs    := ../../extract/export/output/hearings.parquet

jsdir   := output/jsonl
trndir  := output/training

all_labs := output/all-labels.parquet
irr     := output/irr-review.parquet

irr_inputs := output/training/phase1.parquet output/training/phase2.parquet

all: $(all_labs) $(irr)

clean: 
	-rm -r output/*

$(irr): src/agreement.R $(irr_inputs)
	Rscript --vanilla $< \
		--inputs=$(irr_inputs) \
		--output=$@

$(all_labs): src/combine-phases.R \
	output/phase1-all-labels.parquet \
	output/phase2-all-labels.parquet
	Rscript --vanilla $< \
		--phase1=output/phase1-all-labels.parquet \
		--phase2=output/phase2-all-labels.parquet \
		--output=$@

output/hearings.parquet: ../../extract/export/output/hearings.parquet
	-mkdir output
	cd output && ln -s ../$< .

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
