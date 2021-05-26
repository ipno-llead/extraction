input_mins := ../../segment/export/output/minutes.parquet
input_meta := ../../import/export/output/metadata.csv
input_personnel := input/personnel.csv
input_event := input/event.csv

output_mins := output/minutes.parquet
output_meta := output/metadata.csv
output_roster := output/roster.parquet

.PHONY: all clean

all: $(output_mins) $(output_meta) $(output_roster)

clean: 
	-rm -r output/*

$(output_mins): $(input_mins)
	-mkdir output
	cd output && ln -s ../$(input_mins) .

$(output_meta): $(input_meta)
	-mkdir output
	cd output && ln -s ../$(input_meta) .

$(output_roster): src/roster.R $(input_personnel) $(input_event)
	Rscript --vanilla $< \
		--personnel=$(input_personnel) \
		--event=$(input_event) \
		--output=$@

# done.
