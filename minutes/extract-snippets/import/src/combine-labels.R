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
    purrr,
    stringr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--traindir", default = "output/training")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

combined <- list.files(args$traindir,
                       full.names = TRUE,
                       pattern = "*.parquet") %>%
    set_names(basename) %>%
    set_names(tools::file_path_sans_ext) %>%
    map_dfr(read_parquet, .id = "session") %>%
    filter(!is.na(text))

write_parquet(combined, args$output)

# done.
