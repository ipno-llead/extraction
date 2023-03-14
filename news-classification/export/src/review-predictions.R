# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    readr,
    writexl
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--scores", default = "../model/output/articles-scores.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

scores <- read_parquet(args$scores)
labs <- read_parquet("../import/output/labeled-articles.parquet")

scoredata <- scores %>%
    left_join(labs %>% select(article_id, truth = relevant),
              by = "article_id") %>%
    filter(officer) %>%
    mutate(score_group = cut(score_a_relevant, include.lowest = T,
                             breaks = c(0, .3, .7, 1),
                             labels = c("low", "medium", "high")))


to_export <- filter(scoredata, officer) %>%
    select(article_id, text,
           score = score_a_relevant,
           ground_truth = truth, score_group) %>%
    nest(data = -score_group)

output <- structure(to_export$data,
                    names = as.character(to_export$score_group))

write_xlsx(output, "output/article-score-review-20230310.xlsx")
