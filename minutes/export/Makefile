# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

input := ../extract/export/output/all-hearings.xlsx
output := output/all-hearings.xlsx

.PHONY: all clean

all: $(output)

clean: 
	-rm -r output/*

$(output): $(input)
	-mkdir output
	cd output && ln -s ../$(input)

# done.
