# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all import meeting-dates hearing-accused classify-hearings merge export 

all: export

import: 
	cd $@ && make

meeting-dates: import
	cd $@ && make

hearing-accused: import
	cd $@ && make

classify-hearings: import
	cd $@ && make

merge: meeting-dates hearing-accused classify-hearings
	cd $@ && make

export: merge
	cd $@ && make

# done.
