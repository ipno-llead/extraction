# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

pacman::p_load(
    argparse,
    arrow,
    dplyr,
    readr
)

parser <- ArgumentParser()
parser$add_argument("--minutes", default="../export/output/minutes.parquet")
args <- parser$parse_args()

mins <- read_parquet(args$minutes)

files <- read_delim("../../import/export/output/metadata.csv",
                   delim="|", na="",
                   col_types=cols(.default=col_character())) %>%
    select(filepath, )

mins %>% distinct(docid, fileid, pageno) %>%
    group_by(docid, fileid) %>%
    summarise(pg_from = min(pageno), pg_to = max(pageno),
              .groups='drop')
