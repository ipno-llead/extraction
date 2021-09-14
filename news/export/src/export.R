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
parser$add_argument("--news")
parser$add_argument("--uids")
parser$add_argument("--meta")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

news <- read_parquet(args$news)
meta <- read_delim(args$meta, delim = "|")
uids <- read_parquet(args$uids)

news_text <- news %>%
    arrange(fileid, pageno) %>%
    group_by(fileid) %>%
    summarise(text = paste(text, collapse = "\n\n"), .groups = "drop")

matched <- meta %>%
    select(fileid, filename, db_path) %>%
    inner_join(uids, by = "fileid") %>%
    inner_join(news_text, by = "fileid") %>%
    rename(matched_name = roster_name) %>%
    group_by(fileid, candidate_name) %>%
    filter(n_distinct(uid) == 1 | title) %>%
    ungroup %>%
    select(fileid, db_path, uid, matched_name, text)

write_csv(matched, args$output)

#audit
# news %>%
#     anti_join(uids, by = "fileid") %>%
#     inner_join(meta, by = "fileid") %>%
#     distinct(fileid, filename) %>% mutate(fn = basename(filename))
