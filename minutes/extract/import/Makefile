# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

input_mins := ../../segment/export/output/minutes.parquet
input_meta := ../../import/export/output/metadata.csv

wrgldir := ../../../.wrgl

input_personnel := output/personnel.csv
input_event := output/event.csv
agencies := hand/agencies.csv

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
	-wrgl init --wrgl-dir $(wrgldir)
	wrgl pull $* --wrgl-dir $(wrgldir)
	wrgl export --wrgl-dir $(wrgldir) $* > $@

$(output_mins): src/standardize-agency.R $(input_mins) $(agencies)
	-mkdir output
	Rscript --vanilla $< \
		--input=$(input_mins) \
		--agencies=$(agencies) \
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
