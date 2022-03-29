# Authors:     TS
# Maintainers: TS
# Copyright:   2022, HRDAG, GPL v2 or later
# =========================================

hearings := ../../extract/export/output/hearings.parquet
messy := output/messy.parquet

docketnos := output/hearings-dockets.parquet

.PHONY: all clean

all: $(docketnos)

clean: 
	-rm -r output/*

$(docketnos): src/clean-dockets.R $(messy)
	RScript --vanilla $< \
		--input=$(messy) \
		--output=$@

$(messy): src/dockets-spacy.py $(hearings)
	-mkdir output
	python3 $< \
		--hearings=$(hearings) \
		--output=$@

# done.
