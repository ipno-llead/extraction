# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

mins_out := output/minutes-features.parquet
train_out := output/training-data-features.parquet

.PHONY: all clean

all: $(mins_out) $(train_out)

clean: 
	-rm -r output/*

output/%-features.parquet: src/merge.R \
		../import/output/%.parquet \
		../regex/output/%-re.parquet \
		../topics/output/%-topics.parquet
	-mkdir output
	Rscript --vanilla $< \
		--docs=../import/output/$*.parquet \
		--regex=../regex/output/$*-re.parquet \
		--topics=../topics/output/$*-topics.parquet \
		--output=$@

# done.
