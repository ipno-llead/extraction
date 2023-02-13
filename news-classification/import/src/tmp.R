library(arrow)
library(tidyverse)
library(writexl)

articles <- read_parquet("output/all-candidates.parquet")
scores <- read_parquet("../model/output/articles-scores.parquet")
labels <- read_parquet("output/labeled-articles.parquet") %>%
    distinct(article_id, ground_truth = relevant)

scores %>%
    distinct(article_id, score = score_a_relevant) %>%
    inner_join(articles, by = "article_id") %>%
    left_join(labels, by = "article_id") %>%
    select(article_id, score, ground_truth, keyword, officer, text) %>%
    #     mutate(text = str_trunc(text, 32750, "right", ellipsis = "...")) %>%
    #     filter(score > .5) %>%
    filter(!officer | ground_truth != "a_relevant") %>%
    arrange(desc(score)) %>%
    #     filter(officer) %>%
    select(text, score)
