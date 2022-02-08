# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

input_mins := ../../segment/export/output/minutes.parquet
input_meta := ../../import/export/output/metadata.csv

input_personnel := output/personnel.csv
input_event := output/event.csv

output_mins := output/minutes.parquet
output_meta := output/metadata.csv
output_roster := output/roster.parquet

.PHONY: all clean force

all: $(output_mins) $(output_meta) $(output_roster)

clean: 
	-rm -r output/*

# force roster updates from wrgl
force: ;

# running this recipe as one line in order to set api creds as env. variables
# only locally within the recipe
output/%.csv: force
	-wrgl init --wrgl-dir output/$*
	-wrgl remote add origin https://hub.wrgl.co/api/users/ipno/repos/$* --wrgl-dir output/$*
	wrgl pull main origin refs/heads/main:refs/heads/main --set-upstream --wrgl-dir output/$*
	wrgl export --wrgl-dir output/$* main > $@

$(output_mins): src/standardize-agency.R $(input_mins)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(input_mins) \
		--output=$@

$(output_meta): $(input_meta)
	-mkdir output
	cd output && ln -s ../$(input_meta) .

$(output_roster): src/roster.R $(input_personnel) $(input_event)
	Rscript --vanilla $< \
		--personnel=$(input_personnel) \
		--event=$(input_event) \
		--output=$@

# done.
