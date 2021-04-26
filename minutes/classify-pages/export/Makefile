# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

minutes := ../import/output/minutes.parquet
pagetypes := ../classify/output/pagetypes.parquet

output := output/minutes.parquet

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): src/export.R $(minutes) $(pagetypes)
	-mkdir output
	Rscript --vanilla $< \
		--minutes=$(minutes) \
		--pagetypes=$(pagetypes) \
		--output=$@

# done.

