.PHONY: all clean

news_in := ../ocr/output/news-txt.parquet
roster_in := ../officer-roster/output/roster.parquet
meta_in := ../index/output/metadata.csv

outdir := output
news_out := news.parquet
roster_out := roster.parquet
meta_out := metadata.csv

all: $(outdir)/$(news_out) $(outdir)/$(roster_out) $(outdir)/$(meta_out)

$(outdir)/$(news_out): $(news_in)
	-mkdir $(outdir)
	cd $(outdir) && ln -s ../$(news_in) $(news_out)
	
$(outdir)/$(roster_out): $(roster_in)
	-mkdir $(outdir)
	cd $(outdir) && ln -s ../$(roster_in) $(roster_out)
	
$(outdir)/$(meta_out): $(meta_in)
	-mkdir $(outdir)
	cd $(outdir) && ln -s ../$(meta_in) $(meta_out)
	
# done.
