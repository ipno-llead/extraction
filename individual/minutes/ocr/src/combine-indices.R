# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    dplyr,
    purrr,
    readr
)
# }}}

# command line args {{{
parser <- ArgumentParser()
parser$add_argument("--inputs")
parser$add_argument("--dbtask", default="../../../dl-dropbox")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

indices <- strsplit(args$inputs, "\\s+")[[1]]

# indices <- c("../../../dl-dropbox/output/east-baton-rouge/fpcsc/index.csv",
#              "../../../dl-dropbox/output/mandeville/pcsb/index.csv")

map_dfr(indices, read_delim, delim="|", na="", col_types='cccccc') %>%
    select(local_name, sha1_hash) %>%
    transmute(filename = paste(args$dbtask, local_name, sep="/"),
              filesha1=sha1_hash) %>%
    write_delim(args$output, delim="|")

# done.
