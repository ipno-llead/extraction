# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    readr,
    stringr
)
# }}}

# command line args {{{
parser <- ArgumentParser()
parser$add_argument("--inputs")
parser$add_argument("--dbtask")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

indices <- strsplit(args$inputs, "\\s+")[[1]]

ind <- map_dfr(indices, read_delim, delim="|", na="", col_types='cccccc') %>%
    transmute(filename = paste(args$dbtask, local_name, sep="/"),
              filesha1=sha1_hash, url=permalink,
              db_id, db_path, db_content_hash)


# deal with file dupes (same file with different names)
out <- ind %>%
    arrange(filename) %>%
    group_by(filesha1) %>%
    filter(row_number() == 1) %>%
    ungroup

stopifnot(
    "num files shouldn't change" = length(unique(out$filesha1)) == length(unique(ind$filesha1)),
    "should be one row per unique file" = length(unique(out$filesha1)) == nrow(out)
)

write_parquet(out, args$output)

# done.
