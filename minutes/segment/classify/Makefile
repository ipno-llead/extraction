data := ../features/export/output/minutes-features.parquet
model := ../train/output/line-classifier.crfsuite
output := output/line-labels.parquet
src := src/crf.R

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): $(src) $(data) $(model)
	-mkdir output
	Rscript --vanilla $< \
		--data=$(data) \
		--model=$(model) \
		--output=$@ &> output/log.txt

# done.
