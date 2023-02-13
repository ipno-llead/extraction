# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    readr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--scores", default = "../model/output/articles-scores.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

scores <- read_parquet(args$scores)
#labs <- read_parquet("../import/output/labeled-articles.parquet")
out <- scores %>%
    left_join(labs %>% select(article_id, truth = relevant),
              by = "article_id") %>%
    filter(keyword) %>%
    transmute(article_id,
              text,
              score = score_a_relevant,
              relevant = if_else(score > .5, "relevant", "not_relevant"),
              truth) %>%
    arrange(desc(score)) %>%
    filter(is.na(truth) | truth != "a_relevant")

write_csv(out, args$output)

# done.
