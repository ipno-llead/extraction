# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

news := ../import/export/output/news.parquet
roster := ../import/export/output/roster.parquet
annotations := ../annotate/output/news-annotated.rds

ppl_mentioned := output/candidate-officer-names.parquet
ppl_matched := output/uid-matches.parquet

.PHONY: all clean

all: $(ppl_matched)

clean: 
	-rm -r output/*

$(ppl_matched): src/match-officer.R $(ppl_mentioned) $(roster)
	Rscript --vanilla $< \
		--mentions=$(ppl_mentioned) \
		--roster=$(roster) \
		--output=$@

$(ppl_mentioned): src/people.R $(annotations)
	-mkdir output
	Rscript --vanilla $< \
		--annotations=$(annotations) \
		--output=$@

# done.
