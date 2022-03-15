scores := ../generic-models/output/hrg-snippet-scores.parquet
dockets := ../docketnums/output/hearings-dockets.parquet
output := output/hearing-snippets.parquet

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): src/scores2snippets.R $(scores) $(dockets)
	-mkdir output
	Rscript --vanilla $< \
		--scores=$(scores) \
		--dockets=$(dockets) \
		--output=$@

# done.
