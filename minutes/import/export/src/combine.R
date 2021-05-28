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
parser$add_argument("--pdf")
parser$add_argument("--word")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# combine {{{
pdftxt <- read_parquet(args$pdf)
wrdtxt <- read_parquet(args$word)
out <- bind_rows(pdftxt, wrdtxt) %>% arrange(fileid, pageno)
# }}}

write_parquet(out, args$output)

# done.
