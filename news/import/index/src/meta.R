# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================
# extraction/news/import/index/src/meta.R

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    assertr,
    dplyr,
    pdftools,
    purrr,
    readr,
    stringr,
    tidyr
)
# }}}

# args{{{
parser <- ArgumentParser()
parser$add_argument("--input")
parser$add_argument("--dbpath")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# functions{{{
# name relative to repository root
# makes it easier to use from anywhere with e.g. here::here()
repo_name <- function(filename, dbpath=args$dbpath) {
    paste0(dbpath, str_extract(filename, "/output/.*$"))
}

dtct <- function(string, term) str_detect(string, regex(term, ignore_case=TRUE))

# }}}

ind <- read_delim(args$input, delim = "|",
                  col_types = cols(.default = col_character()))

out <- ind %>%
    mutate(filename = file.path(args$dbpath, local_name)) %>%
    mutate(filetype = case_when(
               dtct(filename, "\\.pdf$") ~ "pdf",
               TRUE ~ "unknown"),
           fileid   = str_sub(sha1_hash, 1, 7)) %>%
    verify(filetype == "pdf") %>%
    mutate(fn = basename(filename)) %>%
    mutate(file_category = "news") %>%
    select(fileid, filename, filetype, file_category, filesha1 = sha1_hash,
           starts_with("db_"))

stopifnot(
    "nrows changed"  = nrow(out) == nrow(ind),
    "duplicate fileids" = length(unique(out$fileid)) == nrow(out)
)

write_delim(out, args$output, delim="|", na="")

# done.
