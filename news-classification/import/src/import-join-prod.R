# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    dbplyr,
    DBI,
    RPostgres,
    tidyr
)
# }}}

# connect to db {{{
ppact_connect <- function(ppact_host=Sys.getenv("PPACT_POSTGRES_HOST"),
                          ppact_user=Sys.getenv("PPACT_POSTGRES_USER"),
                          ppact_pw=Sys.getenv("PPACT_POSTGRES_PW")) {
    DBI::dbConnect(
        RPostgres::Postgres(),
        host=ppact_host,
        port=5432,
        dbname="ipno",
        user=ppact_user,
        password=ppact_pw)
}
# }}}

# assemble data {{{
# a "keyword candidate" story is one that was flagged in the keyword filter. an
# "officer candidate" story is a keyword candidate that also matched an officer
# name.
identify_candidates <- function(keyword, officer) {
    keyword %>%
        select(article_id, sentence_id, keyword) %>%
        left_join(distinct(officer, sentence_id, officer),
                  by = "sentence_id") %>%
        replace_na(list(officer = FALSE)) %>%
        group_by(article_id) %>%
        summarise(keyword = any(keyword),
                  officer = any(officer), .groups = "drop")
}

# Of the candidates, an `irrelevant` story is one that was `hidden` during
# review, and all stories that are not `irrelevant` are therefore `relevant`
# the practice of using the `hidden` flag for this purpose began in early 2022,
# and we expect there to be some lag on more recent articles that haven't been
# reviewed yet
create_training_set <- function(articles, candidates) {
    candidates %>%
        inner_join(articles, by = "article_id") %>%
        filter(officer) %>%
        filter(created_at >= as.Date("2022-01-01"),
               created_at <= as.Date("2022-11-07")) %>%
        transmute(article_id, text,
                  relevant = if_else(is_hidden,
                                     "b_norelevant",
                                     "a_relevant")) %>%
        distinct
}

# note: required for generating new classifications/reviewing existing
compile_articles <- function(articles, candidates) {
    articles %>%
        distinct(article_id, text) %>%
        left_join(candidates, by = "article_id") %>%
        replace_na(list(keyword = FALSE, officer = FALSE))
}

# }}}

# wrapping everything in `main` function to ensure we release the db connection
# no matter how things go
main <- function() { # {{{
    con <- ppact_connect()
    on.exit(dbDisconnect(con))

    articles <- tbl(con, "news_articles_newsarticle") %>%
        rename(article_id = id) %>%
        mutate(text = paste(title, content, sep = " "))
    keyword <- tbl(con, "news_articles_matchedsentence") %>%
        rename(sentence_id = id) %>% mutate(keyword = TRUE)
    officer <- tbl(con, "news_articles_matchedsentence_officers") %>%
        rename(sentence_id = matchedsentence_id) %>% mutate(officer = TRUE)

    candidates <- identify_candidates(keyword, officer)
    labels <- create_training_set(articles, candidates)
    all_articles  <- compile_articles(articles, candidates)

    out <- list(labels = collect(labels),
                articles = collect(all_articles))

    stopifnot(length(unique(out$labels$article_id)) == nrow(out$labels))
    stopifnot(length(unique(out$all_articles$article_id)) == nrow(out$all_articles))
    out
}
# }}}

out <- main()

write_parquet(out$labels, "output/labeled-articles.parquet")
write_parquet(out$articles, "output/all-candidates.parquet")

# done.
