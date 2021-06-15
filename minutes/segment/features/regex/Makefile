# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

in_dir := ../import/output

in_mins := $(in_dir)/minutes.parquet
in_train := $(in_dir)/training-data.parquet

out_mins := output/minutes-re.parquet
out_train := output/training-data-re.parquet

regexes := hand/regexes.yaml
docs2feats := src/re-feats.R

.PHONY: all clean

all: $(out_mins) $(out_train)

clean: 
	-rm -r output/*

output/%-re.parquet: $(docs2feats) $(in_dir)/%.parquet $(regexes)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(in_dir)/$*.parquet \
		--regexes=$(regexes) \
		--output=$@

# done.
