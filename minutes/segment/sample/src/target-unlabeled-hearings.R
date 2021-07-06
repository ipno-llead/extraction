# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    readr,
    stringr,
    tidyr
)

parser <- ArgumentParser()
parser$add_argument("--input", default = "../export/output/minutes.parquet")
parser$add_argument("--already", default = "frozen")
parser$add_argument("--sampsize", type = "integer", default = 15L)
parser$add_argument("--overweight")
parser$add_argument("--output")
args <- parser$parse_args()

already <- list.files(args$already, full.names = TRUE) %>%
    map(readLines) %>% unlist %>% unique

docs <- read_parquet(args$input) %>% filter(! docid %in% already)

sampled <- docs %>%
    filter(str_detect(text, "(APPEAL HEARING)|(HEARING OF APPEAL)"),
           ! linetype %in% c("hearing", "hearing_header")) %>%
    distinct(docid) %>%
    sample_n(args$sampsize)

writeLines(sampled$docid, args$output)

# done.
