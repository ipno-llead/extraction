# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

pacman::p_load(
    argparse,
    arrow,
    dplyr
)

parser <- ArgumentParser()
parser$add_argument("--minutes")
parser$add_argument("--pagetypes")
parser$add_argument("--output")
args <- parser$parse_args()

mins <- read_parquet(args$minutes)
labs <- read_parquet(args$pagetypes)

out <- mins %>%
    select(fileid, starts_with("f_"), pageno, text) %>%
    inner_join(labs, by=c("fileid", "pageno"))

stopifnot(nrow(out) == nrow(mins))

write_parquet(out, args$output)
