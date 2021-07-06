data := ../features/export/output/minutes-features.parquet
model := ../train/output/line-classifier.crfsuite
output := output/line-labels.parquet
truth := ../import/output/training-data.parquet
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
		--truth=$(truth) \
		--output=$@ &> output/log.txt

# done.
