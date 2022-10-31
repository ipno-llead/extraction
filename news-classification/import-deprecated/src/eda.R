# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    readr,
    dplyr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--newstext", default = "input/news_articles_newsarticle.csv.gz")
parser$add_argument("--newsincluded", default = "input/news_articles_matchedsentence.csv.gz")
parser$add_argument("--newstrue", default = "input/news_articles_matchedsentence_officers.csv.gz")
args <- parser$parse_args()
# }}}

news <- read_csv(args$newstext) %>%
    select(article_id = id, url, author, title, content)

training <- read_csv(args$newsincluded) %>%
    distinct(article_id, sentenceid = id)

labs <- read_csv(args$newstrue) %>%
    distinct(sentenceid = matchedsentence_id, label = TRUE)

training %>% inner_join(news, by = "article_id") %>%
    left_join(labs, by = "sentenceid") %>%
    group_by(article_id) %>%
    mutate(label = any(label) %>% replace_na(FALSE)) %>%
    ungroup %>% select(-sentenceid) %>% distinct %>%
    count(label)

