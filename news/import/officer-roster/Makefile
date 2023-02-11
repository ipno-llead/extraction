# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

input_personnel := output/working/personnel.csv
input_event := output/working/event.csv

wrgldir := ../../../.wrgl

output_roster := output/roster.parquet

build_roster := ../../../minutes/extract/import/src/roster.R

.PHONY: all clean force

all: $(output_roster)

clean: 
	-rm -r output/*

# force roster updates from wrgl
force: ;

# running this recipe as one line in order to set api creds as env. variables
# only locally within the recipe
output/working/%.csv: force
	-mkdir -p output/working
	-wrgl init --wrgl-dir $(wrgldir)
	wrgl pull $* --wrgl-dir $(wrgldir)
	wrgl export --wrgl-dir $(wrgldir) $* > $@

$(output_roster): $(build_roster) $(input_personnel) $(input_event)
	Rscript --vanilla $< \
		--personnel=$(input_personnel) \
		--event=$(input_event) \
		--output=$@

# done.
