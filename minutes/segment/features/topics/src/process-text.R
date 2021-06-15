# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
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
parser$add_argument("--input")
parser$add_argument("--dfout")
parser$add_argument("--txtout")
args <- parser$parse_args()
# }}}

# helpers {{{
norm_case <- function(strings) {
    str_to_lower(strings)
}

norm_text <- function(string) {
    str_split(string, "\\s+")[[1]] %>%
        str_replace_all("[^A-Za-z0-9 :()#]", " ") %>%
        str_trim %>%
        str_replace_all("([^A-Za-z0-9_])", " \\1 ") %>%
        str_replace_all("(^| )[0-9]{1}($| )", " _D_ ") %>%
        str_replace_all("(^| )[0-9]{2,}($| )", " _DD_ ") %>%
        norm_case %>%
        paste(collapse = " ") %>%
        str_squish
}
# }}}

input <- read_parquet(args$input)

out <- input %>%
    mutate(normtext = map_chr(text, norm_text)) %>%
    arrange(docid, docpg, lineno) %>%
    select(docid, docpg, lineno, normtext)

export <- out %>%
    group_by(docid) %>%
    summarise(normtext = paste(normtext, collapse = " "))

writeLines(export$normtext, args$txtout)
write_parquet(out, args$dfout)

# done.
