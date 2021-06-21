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
    SnowballC,
    stringr,
    tidyr
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

make_re <- function(vect) paste0("(", vect, ")", collapse="|")

re_month <- str_to_lower(month.name) %>% make_re

re_day <- c("monday", "tuesday", "wednesday",
            "thursday", "friday", "saturday",
            "sunday") %>% make_re

norm_text <- function(strings) {
    str_replace_all(strings, "[^A-Za-z0-9 :()#]", " ") %>%
        str_trim %>%
        str_replace_all("([^A-Za-z0-9_])", " \\1 ") %>%
        norm_case %>%
        str_replace_all(re_month, " _MONTH_ ") %>%
        str_replace_all(re_day, " _DAY_ ") %>%
        str_replace_all("[0-9]+", " _NUM_ ") %>%
        str_trim %>%
        wordStem(language = "english")
}
# }}}

input <- read_parquet(args$input)

out <- input %>%
    mutate(token = str_split(text, "\\s+"),
           token_seqid = map(token, seq_along)) %>%
    unnest(c(token_seqid, token)) %>%
    mutate(normtoken = norm_text(token)) %>%
    arrange(docid, docpg, lineno, token_seqid) %>%
    group_by(docid, docpg, lineno) %>%
    summarise(normtext = paste(normtoken, collapse = " ") %>% str_squish,
              .groups = "drop")

export <- out %>%
    group_by(docid) %>%
    summarise(normtext = paste(normtext, collapse = " "))

writeLines(export$normtext, args$txtout)
write_parquet(out, args$dfout)

# done.
