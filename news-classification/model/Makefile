# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

## language model should improve if trained on news.parquet 
#languagedata := ../import/output/news.parquet
#traindata := ../import/output/train.parquet
#testdata := ../import/output/test.parquet

# note: we've been training the model on Google Colab and using a frozen model
# snapshot. using scripts here just for generating new predictions, not for
# training. `testdata` is the data which we want to generate predictions on,
# must have a `text` column
model :=  frozen/trained-classifier-exported.zip
testdata := ../import/output/all-candidates.parquet
scores := output/articles-scores.parquet

train := src/model.py
score := src/score.py

.PHONY: all

all: $(scores)

$(model): $(train) $(languagedata) $(traindata) 
	-mkdir output
	python $< \
		--lm_input=$(languagedata) \
		--cm_input=$(traindata) \
		--modeloutput=$(model)
	
$(scores): $(score) $(testdata) $(model)
	python $< \
		--data=$(testdata) \
		--model=$(model) \
		--scores=$@

# done.
