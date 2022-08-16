# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all clean

hrgs    := ../../extract/export/output/hearings.parquet

jsdir   := output/jsonl
trndir  := output/training

all_labs := output/all-labels.parquet
#all_labs := \
#	    output/llead-document-tagging-all-labels.parquet \
#	    output/review-extracted-hearings-all-labels.parquet \
#	    output/hearing-text-staging-all-labels.parquet

irr     := output/irr-review.parquet

#irr_inputs := input/llead-document-tagging.zip \
#	      input/review-extracted-hearings.zip \
#	      input/hearing-text-staging.zip

all: $(all_labs)

clean:
	-rm -r output/*

#$(irr): src/agreement.R $(irr_inputs)
#	Rscript --vanilla $< \
#		--inputs="$(irr_inputs)" \
#		--output=$@

$(all_labs): src/combine-labels.R \
	output/training/hearing-text-staging.parquet \
	output/training/llead-document-tagging.parquet \
	output/training/review-extracted-hearings.parquet
	Rscript --vanilla $< \
		--traindir="output/training" \
		--output=$@


#$(all_labs): src/combine-phases.R \
#	output/llead-document-tagging-all-labels.parquet \
#	output/review-extracted-hearings-all-labels.parquet
#	Rscript --vanilla $< \
#		--phase1=output/llead-document-tagging-all-labels.parquet \
#		--phase2=output/review-extracted-hearings-all-labels.parquet \
#		--output=$@

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

output/%-all-labels.parquet: src/prep-labs.R $(trndir)/%.parquet
	Rscript --vanilla $< \
		--input=$(trndir)/$*.parquet \
		--output=$@

# done.
