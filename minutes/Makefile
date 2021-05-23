# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all import classify-pages segment extract export

all: export

import: 
	cd $@ && make

classify-pages: import
	cd $@ && make

segment: classify-pages
	cd $@ && make

extract: segment
	cd $@ && make

export: extract
	cd $@ && make

# done.
