# Authors:     BP
# Maintainers: BP
# Copyright:   2022, HRDAG, GPL v2 or later
# =========================================
# extraction/news-classification/import/Makefile

# downloaded tables
news_included := input/news_articles_matchedsentence.csv.gz
news_true := input/news_articles_matchedsentence_officers.csv.gz
news_text := input/news_articles_newsarticle.csv.gz

# hand fixes
p1 := hand/review_random.yml
p2 := hand/review_testdf.csv
p3 := hand/to_label_ai.xlsx

# task output
merged := output/merged.parquet
train := output/train.parquet
dup_report := output/dup_groups.yml

.PHONY: all clean fixed

all: $(merged) fixed $(train) $(dup_report)

clean: 
	-rm -r output/*

$(dup_report): \
		src/make_reports.py \
		$(merged)
	-mkdir output
	python3 $< \
		--news=$(merged) \
		--output=$@

$(train): \
		src/make_train_test.py \
		$(merged)
	-mkdir output
	python3 $< \
		--input=$(merged) \
		--output=$@

fixed: \
		src/patch_relevant.py \
		$(merged)
	-mkdir output
	python3 $< \
		--input=$(merged) \
		--p1=$(p1) \
		--p2=$(p2) \
		--p3=$(p3)

$(merged): \
		src/import.py \
		$(news_included) \
		$(news_true) \
		$(news_text)
	-mkdir output
	python3 $< \
		--included=$(news_included) \
		--true=$(news_true) \
		--text=$(news_text) \
		--output=$@

# done.