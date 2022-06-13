# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2022, HRDAG, GPL v2 or later
# =========================================

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--phase1", default = "output/phase1-all-labels.parquet")
parser$add_argument("--phase2", default = "output/phase2-all-labels.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

out <- list(phase1 = args$phase1, phase2 = args$phase2) %>%
    map_dfr(read_parquet, .id = "phase")

write_parquet(out, args$output)

# done.
