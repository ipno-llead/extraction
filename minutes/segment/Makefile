# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all import features train classify export sample

all: export

import: 
	cd $@ && make

features: import
	cd $@ && make

train: features
	cd $@ && make

classify: train import
	cd $@ && make

export: classify import
	cd $@ && make

sample: export
	cd $@ && make

# done.
