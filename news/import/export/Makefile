.PHONY: all clean

input := ../ocr/output/news-txt.parquet

outdir := output
outnm := news.parquet

output := $(outdir)/$(outnm)

all: $(output)

$(output): $(input)
	-mkdir $(outdir)
	cd $(outdir) && ln -s ../$(input) $(outnm)
	
# done.
