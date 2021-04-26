.PHONY: all clean

all: output/minutes.parquet output/metadata.csv

clean: 
		-rm -r output/*

output/minutes.parquet: ../ocr/output/minutes.parquet
	-mkdir output
	cd output && ln -s ../../ocr/output/minutes.parquet .

output/metadata.csv: ../index/output/metadata.csv
	-mkdir output
	cd output && ln -s ../../index/output/metadata.csv
