# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all wrgl

all: wrgl

wrgldir := ../../.wrgl
output := ../../output/news_article_classification.csv

scores := ../model/output/articles-scores.parquet

all: 

wrgl: $(output)
	-wrgl init --wrgl-dir $(wrgldir)
	wrgl pull news_article_classification --wrgl-dir $(wrgldir) --depth 1
	cd $(dir $(wrgldir)) && wrgl commit news_article_classification "update news article classifications"
	wrgl push origin refs/heads/news_article_classification: --wrgl-dir $(wrgldir)

$(output): src/export.R $(scores)
	Rscript --vanilla $< \
		--scores=$(scores) \
		--output=$@

# done.

