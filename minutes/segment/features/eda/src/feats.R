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
parser$add_argument("--input", default = "../import/output/training-data.parquet")
parser$add_argument("--topics", default = "../word2vec/output/document-topics.parquet")
parser$add_argument("--regexes", default = "hand/regexes.yaml")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# helper functions {{{
hascaps <- function(string) str_detect(string, "[A-Z]")

allcaps <- function(string) {
    str_detect(string, "[A-Z]") & !str_detect(string, "[a-z]")
}

dtct<- function(string, pattern) {
    pat <- if (hascaps(pattern)) pattern else regex(pattern, ignore_case=TRUE)
    as.integer(str_detect(string, pat))
}
# }}}

doclines <- read_parquet(args$input)
topics <- read_parquet(args$topics)
regexes <- read_yaml(args$regexes)

norm_case <- function(strings) {
    str_to_lower(strings)
    #     haslower <- str_detect(strings, "[a-z]")
    #     out <- strings
    #     out[haslower] <- str_to_lower(strings[haslower])
    #     out
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

feats <- doclines %>%
    mutate(map_dfc(regexes, ~dtct(text, .)),
           caps_pct = str_count(text, "[A-Z]") / str_length(text),
           frontpage = docpg == 1,
           normtext = map_chr(text, norm_text)) %>%
    inner_join(topics, by = c("docid", "docpg", "lineno")) %>%
    select(fileid, pageno, docid, docpg, lineno, f_region,
           starts_with("re_"), starts_with("topic_"),
           caps_pct, frontpage, text, normtext,
           # this is only in the labeled data, allows us to same script
           # to process both
           matches("^label$")) %>%
    arrange(docid, docpg, lineno) %>%
    group_by(docid, docpg) %>%
    mutate(gap1 = lineno > lag(lineno) + 1,
           gap2 = lineno > lag(lineno) + 2) %>%
    ungroup %>%
    replace_na(list(gap1 = FALSE, gap2 = FALSE)) %>%
    mutate(across(c(gap1, gap2, frontpage), as.integer)) %>%
    arrange(docid, docpg, lineno)

out <- feats %>%
    group_by(docid) %>%
    mutate(across(c(starts_with("re_"), starts_with("topic_"),
                    "caps_pct", "gap1", "gap2"),
                  lag, 1, .names = "prv_{col}_1"),
           across(c(starts_with("re_"), starts_with("topic_"),
                    "caps_pct", "gap1", "gap2"),
                  lead, 1, .names = "nxt_{col}_1")) %>%
    ungroup %>%
    mutate(across(c(starts_with("prv_"), starts_with("nxt_")),
                  replace_na, 0))

stopifnot(nrow(out) == nrow(doclines))

write_parquet(out, args$output)

# done.
