## language model should improve if trained on news.parquet 
languagedata := ../import/output/train-test.parquet
traindata := ../import/output/train.parquet
testdata := ../import/output/test.parquet

model :=  output/model.pth
scores := output/test-scores.parquet

train := src/model.py
score := src/score.py

.PHONY: all

all: $(scores)

$(model): $(train) $(languagedata) $(traindata) 
	-mkdir output
	python3 $< \
		--lm_input=$(languagedata) \
		--cm_input=$(traindata) \
		--modeloutput=$(model)
	
$(scores): $(score) $(testdata) $(model)
	python3 $< \
		--data=$(testdata) \
		--model=$(model) \
		--scores=$@

# done.