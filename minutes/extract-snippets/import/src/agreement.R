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
    fs,
    purrr,
    stringr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--inputs", default = "output/training/phase1.parquet output/training/phase2.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

paths <- fs::as_fs_path(flatten_chr(str_split(args$inputs, " "))) %>%
    set_names(path_ext_remove)
stopifnot(all(file_exists(paths)))

tmp <- map_dfr(paths, read_parquet, .id = "session")

distinct(labs, hrgno, docid, labeler, start, end, label) %>%
