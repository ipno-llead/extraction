# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

hrgdata   := ../import/output/hrg-sentences.parquet
traindata := ../import/output/phase2-all-labels.parquet

model :=  output/snippet-classifier.pkl
scores := output/hrg-snippet-scores.parquet

train := src/model.py
score := src/score.py

.PHONY: all

all: $(scores)

$(model): $(train) $(traindata)
	-mkdir output
	python3 $< \
		--input=$(traindata) \
		--modelout=snippet-classifier.pkl
	
$(scores): $(score) $(hrgdata) $(model)
	python3 $< \
		--data=$(hrgdata) \
		--model=$(model) \
		--scores=$@
# done.
