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
    dplyr,
    logger,
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

# helper functions{{{
hascaps <- function(string) str_detect(string, "[A-Z]")

smartmatch <- function(string, pattern) {
    pat <- if (hascaps(pattern)) pattern else regex(pattern, ignore_case=TRUE)
    str_match(string, pat)[,2]
}
# }}}

hearings <- read_parquet(args$input) %>%
    filter(linetype %in% c("hearing_header", "hearing"), !is.na(hrgno)) %>%
    arrange(docid, docpg, lineno) %>%
    group_by(docid, hrgno) %>%
    slice_head(n = 7) %>%
    ungroup

re <- read_yaml(args$regexes)

log_info(distinct(hearings, docid, hrgno) %>% nrow, " hearings to start")

# extraction {{{
accused <- hearings %>%
    mutate(text = str_squish(text)) %>%
    select(docid, hrgno, text) %>%
    mutate(map_dfc(re, ~smartmatch(text, .))) %>%
    pivot_longer(cols = starts_with("re_"),
                 names_to = "regex",
                 values_to = "hrg_accused") %>%
    filter(!is.na(hrg_accused)) %>%
    distinct(docid, hrgno, hrg_accused)

log_info(distinct(accused, docid, hrgno) %>% nrow,
         " hearings with accused name identified and extracted")

# }}}

# deal with ambiguous matches {{{
ambiguous <- accused %>%
    group_by(docid, hrgno) %>%
    filter(n() > 1) %>%
    ungroup %>% distinct(docid, hrgno)

log_info(nrow(ambiguous), " hearings with multiple possible accused names",
         ", defaulting to the first match")

out <- accused %>% group_by(docid, hrgno) %>%
    filter(row_number() == 1) %>% ungroup
# }}}

write_parquet(out, args$output)

# done.
