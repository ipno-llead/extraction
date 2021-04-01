minutes := ../../ocr/output/minutes.parquet

.PHONY: all clean

all: output/minutes.parquet

clean: 
	-rm -r output/*

output/minutes.parquet: $(minutes)
	-mkdir output
	cd output && ln -s ../$(minutes) .
