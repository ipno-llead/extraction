# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all dl-dropbox index ocr worddoc-text export

all: export

dl-dropbox: 
	cd $@ && make

index: dl-dropbox
	cd $@ && make

ocr: index
	cd $@ && make

worddoc-text: index
	cd $@ && make

export: ocr worddoc-text
	cd $@ && make

# done.
