input := ../import/output/minutes.parquet
output := output/minutes.parquet
src := src/heuristic.R

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): $(src) $(input)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(input) \
		--output=$@

# done.
