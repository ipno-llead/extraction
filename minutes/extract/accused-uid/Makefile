# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

xtract := ../hearing-accused/output/hrg-accused.parquet
dates := ../meeting-dates/output/mtg-dates.parquet
roster := ../import/output/roster.parquet
classes := ../classify-hearings/output/hrg-class.parquet
docxref := ../import/output/minutes.parquet

output := output/hrg-accused-uid.parquet
src := src/match-accused.R

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): $(src) $(xtract) $(dates) $(roster) $(classes) $(docxref)
	-mkdir output
	Rscript --vanilla $< \
		--xtract=$(xtract) \
		--dates=$(dates) \
		--classes=$(classes) \
		--docxref=$(docxref) \
		--roster=$(roster) \
		--output=$@ &> output/log.txt

# done.
