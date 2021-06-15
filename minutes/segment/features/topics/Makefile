# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

txt_mins := output/working/minutes-normed.parquet
traintxt := output/working/minutes-text.txt

vecs := output/trained-vectors.txt

.PHONY: all clean

all: output/minutes-topics.parquet output/training-data-topics.parquet

clean: 
	-rm -r output/*

output/%-topics.parquet: src/export-line-topics.jl \
	$(vecs) \
	output/working/%-normed.parquet
	julia --project=. -e 'using Pkg; Pkg.instantiate();'
	JULIA_NUM_THREADS=6 julia --project=. $< \
		$(vecs) \
		output/working/$*-normed.parquet \
		$@

output/working/%-normed.parquet: src/process-text.R \
	../import/output/%.parquet
	-mkdir -p output/working
	Rscript --vanilla $< \
		--input=../import/output/$*.parquet \
		--dfout=output/working/$*-normed.parquet \
		--txtout=output/working/$*-text.txt

$(vecs): src/train-model.jl $(txt_mins)
	julia --project=. -e 'using Pkg; Pkg.instantiate();'
	JULIA_NUM_THREADS=6 julia --project=. $< \
		$(traintxt) \
		$@

# done.
