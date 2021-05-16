input := ../../segment/export/output/minutes.parquet
input_meta := ../../import/export/output/metadata.csv
output := output/minutes.parquet
output_meta := output/metadata.csv

.PHONY: all clean

all: $(output) $(output_meta)

clean: 
	-rm -r output/*

$(output): $(input)
	-mkdir output
	cd output && ln -s ../$(input) .

$(output_meta): $(input_meta)
	-mkdir output
	cd output && ln -s ../$(input_meta) .
