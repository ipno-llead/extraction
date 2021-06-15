# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    stringr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--docs", default = "../import/output/training-data.parquet")
parser$add_argument("--regex", default = "../regex/output/training-data-re.parquet")
parser$add_argument("--topics", default = "../topics/output/training-data-topics.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

docs <- read_parquet(args$docs)
re <- read_parquet(args$regex)
topix <- read_parquet(args$topics)

out <- docs %>%
    inner_join(re, by = c("docid", "docpg", "lineno")) %>%
    inner_join(topix, by = c("docid", "docpg", "lineno")) %>%
    mutate(feat_caps = str_count(text, "[A-Z]") / str_length(text) > .5) %>%
    arrange(docid, docpg, lineno) %>%
    group_by(docid, docpg) %>%
    mutate(feat_gap1 = lineno > lag(lineno) + 1,
           feat_gap2 = lineno > lag(lineno) + 2) %>%
    ungroup %>% group_by(docid) %>%
    mutate(feat_newpage = docpg != lag(docpg)) %>%
    ungroup %>%
    replace_na(list(feat_gap1 = FALSE,
                    feat_gap2 = FALSE,
                    feat_newpage = TRUE)) %>%
    mutate(across(starts_with("feat_"), as.integer)) %>%
    arrange(docid, docpg, lineno)

write_parquet(out, args$output)

# done.
