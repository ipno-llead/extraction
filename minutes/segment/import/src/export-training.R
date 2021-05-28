# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--minutes", default = "output/minutes.parquet")
parser$add_argument("--labels", default = "output/working/trainlabs.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

mins <- read_parquet(args$minutes)
labs <- read_parquet(args$labels)

out <- labs %>%
    inner_join(mins, by = c("fileid", "pageno", "lineno")) %>%
    select(docid, doctype, fileid,
           f_region, f_year, f_month, f_day,
           pageno, lineno, text, label = actual)

stopifnot(nrow(out) == nrow(labs))

write_parquet(out, args$output)

# done.
