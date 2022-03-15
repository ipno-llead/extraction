hearings := ../../extract/export/output/hearings.parquet
docketnos := output/hearings-dockets.parquet

.PHONY: all clean

all: $(docketnos)

clean: 
	-rm -r output/*

$(docketnos): src/dockets-spacy.py $(hearings)
	python3 $< \
		--hearings=$(hearings) \
		--output=$@

# done.
