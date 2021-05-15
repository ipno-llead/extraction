input := ../../classify-pages/export/output/minutes.parquet
output := output/minutes.parquet

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): $(input)
	-mkdir output
	cd output && ln -s ../$(input)

# done.
