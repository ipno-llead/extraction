.PHONY: all clean

news_in := ../ocr/output/news-txt.parquet
roster_in := ../officer-roster/output/roster.parquet

outdir := output
news_out := news.parquet
roster_out := roster.parquet

all: $(outdir)/$(news_out) $(outdir)/$(roster_out)

$(outdir)/$(news_out): $(news_in)
	-mkdir $(outdir)
	cd $(outdir) && ln -s ../$(news_in) $(news_out)
	
$(outdir)/$(roster_out): $(roster_in)
	-mkdir $(outdir)
	cd $(outdir) && ln -s ../$(roster_in) $(roster_out)
	
# done.
