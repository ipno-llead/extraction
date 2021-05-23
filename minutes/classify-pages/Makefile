# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all import features classify export

all: export

import: 
	cd $@ && make

features: import
	cd $@ && make

classify: features
	cd $@ && make

export: classify
	cd $@ && make

sample: import
	cd $@ && make

# done.
