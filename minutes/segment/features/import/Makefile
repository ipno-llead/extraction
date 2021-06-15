# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

in_corpus := ../../import/output/minutes.parquet
in_train  := ../../import/output/training-data.parquet

.PHONY: all clean corpus train

all: output/minutes.parquet output/training-data.parquet

clean: 
	-rm -r output/*

output/%.parquet: ../../import/output/%.parquet
	-mkdir output
	cd output && ln -s ../$< .
	
# done.
