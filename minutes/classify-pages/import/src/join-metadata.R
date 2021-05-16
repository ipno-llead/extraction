# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================
# extraction/minutes/classify-pages/import/src/join-metadata.R

pacman::p_load(
    argparse,
    arrow,
    dplyr,
    readr,
    stringr
)


parser <- ArgumentParser()
parser$add_argument("--text")
parser$add_argument("--meta")
parser$add_argument("--labs")
parser$add_argument("--output")
args <- parser$parse_args()

mins <- read_parquet(args$text)
meta <- read_delim(args$meta, delim="|", na="",
                   col_types = cols(.default = col_character(),
                                    year = col_integer(),
                                    month = col_integer(),
                                    day = col_integer()))
meta <- select(meta, fileid, f_cat=file_category,
               f_region=region, f_year=year, f_month=month, f_day=day)

labs <- read_parquet(args$labs)
joined <- meta %>% inner_join(mins, by="fileid") %>%
    left_join(labs, by=c("fileid", pageno="pg")) %>%
    mutate(labeled = !is.na(label))

stopifnot(nrow(joined) == nrow(mins))

out <- joined %>%
    filter(f_cat == "minutes", str_squish(text) != "")

write_parquet(out, args$output)

# done.
