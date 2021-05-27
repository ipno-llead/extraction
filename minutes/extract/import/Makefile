# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

input_mins := ../../segment/export/output/minutes.parquet
input_meta := ../../import/export/output/metadata.csv

input_personnel := output/working/personnel.csv
input_event := output/working/event.csv

wrglctl := ../../../share/bin/wrglctl
wrgl_creds := ../../../share/creds/wrgl-creds.txt

output_mins := output/minutes.parquet
output_meta := output/metadata.csv
output_roster := output/roster.parquet

.PHONY: all clean

all: $(output_mins) $(output_meta) $(output_roster)

clean: 
	-rm -r output/*

output/working/%.csv: $(wrgl_creds) $(input_mins)
	-mkdir output/working
	set -o allexport; source $(wrgl_creds); set +o allexport
	$(wrglctl) login --apikey=${WRGL_APIKEY}
	$(wrglctl) repos pull @ipno/$* $@

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
