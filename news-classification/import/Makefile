# Authors:     BP
# Maintainers: BP
# Copyright:   2022, HRDAG, GPL v2 or later
# =========================================
# extraction/news-classification/import/Makefile

news_included := input/news_articles_matchedsentence.csv.gz
news_true := input/news_articles_matchedsentence_officers.csv.gz
news_text := input/news_articles_newsarticle.csv.gz
output := output/news.parquet

dup_report := output/dup_groups.yml

.PHONY: all clean

all: $(output) $(dup_report)

clean: 
	-rm -r output/*

$(dup_report): \
		src/duplicate_report.py \
		$(output)
	-mkdir output
	python3 $< \
		--news=$(output) \
		--output=$@

$(output): \
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