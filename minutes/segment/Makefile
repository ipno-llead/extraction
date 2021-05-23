# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all import classify export sample

all: export

import: 
	cd $@ && make

classify: import
	cd $@ && make

export: classify
	cd $@ && make

sample: export
	cd $@ && make

# done.
