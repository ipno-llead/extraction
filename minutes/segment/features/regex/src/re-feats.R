# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    stringr,
    tidyr,
    yaml
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input")
parser$add_argument("--regexes")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# helper functions {{{
hascaps <- function(string) str_detect(string, "[A-Z]")

dtct<- function(string, pattern) {
    pat <- if (hascaps(pattern)) pattern else regex(pattern, ignore_case=TRUE)
    as.integer(str_detect(string, pat))
}
# }}}

doclines <- read_parquet(args$input)
regexes <- read_yaml(args$regexes)

feats <- doclines %>%
    mutate(map_dfc(regexes, ~dtct(text, .))) %>%
    select(docid, docpg, lineno, starts_with("re_"))

stopifnot(nrow(feats) == nrow(doclines))

write_parquet(feats, args$output)

# done.
