# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

meetings := ../import/output/minutes.parquet
dates := ../meeting-dates/output/mtg-dates.parquet
hearingtypes := ../classify-hearings/output/hrg-class.parquet
accused := ../hearing-accused/output/hrg-accused.parquet

output := output/hearings.parquet
src := src/meetings-hearings.R

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): $(src) $(meetings) $(dates) $(hearingtypes) $(accused)
	-mkdir output
	Rscript --vanilla $< \
		--meetings=$(meetings) \
		--dates=$(dates) \
		--hearingtypes=$(hearingtypes) \
		--accused=$(accused) \
		--output=$@

# done.
