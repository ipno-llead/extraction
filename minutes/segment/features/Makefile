.PHONY: all clean import regex topics export

all: export

clean: 
	-rm -r output/*

export: import regex topics
	cd $@ && make
	
regex: import
	cd $@ && make
	
topics: import
	cd $@ && make

import: 
	cd $@ && make

# done.
