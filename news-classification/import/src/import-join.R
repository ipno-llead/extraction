# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    readr,
    dplyr,
    purrr,
    stringr,
    tidyr,
    tools
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--snapshotdir")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

alldata <- fs::dir_ls(args$snapshotdir) %>%
    set_names(basename) %>%
    set_names(file_path_sans_ext) %>%
    set_names(str_replace_all, "\\-", "_") %>%
    map(read_csv)

staging_candidates <- alldata$articles_staging %>%
    select(article_id = id, article_guid = guid, title, content,
           is_processed, is_hidden, processed_dt = created_at) %>%
    left_join(alldata$matched_staging %>%
                  select(article_id, sentence_id = id, matched_sent = text),
              by = "article_id") %>%
    left_join(alldata$matched_officer_staging %>%
                  transmute(sentence_id = matchedsentence_id,
                            matched_officer = T),
              by = "sentence_id") %>%
    mutate(sent_cand = !is.na(sentence_id),
           ofcr_cand = !is.na(matched_officer)) %>%
    group_by(article_id, article_guid) %>%
    summarise(title = unique(title),
              content = unique(content),
              processed_dt = min(processed_dt),
              sent_cand = any(sent_cand),
              ofcr_cand = any(ofcr_cand), .groups = "drop")

stopifnot(length(unique(staging_candidates$article_id)) == nrow(staging_candidates))

prod_labs <- alldata$articles_prod %>%
    select(article_id = id, article_guid = guid, title, content,
           is_processed, is_hidden, processed_dt = created_at) %>%
    left_join(alldata$matched_prod %>%
                  select(article_id, sentence_id = id, matched_sent = text),
              by = "article_id") %>%
    left_join(alldata$matched_officer_prod %>%
                  transmute(sentence_id = matchedsentence_id,
                            matched_officer = T),
              by = "sentence_id") %>%
    replace_na(list(matched_officer = F)) %>%
    mutate(flagged_relevant = matched_officer & !is_hidden & is_processed,
           flagged_irrelevant = matched_officer & is_hidden & is_processed) %>%
    select(article_id, article_guid, title, content,
           is_processed, is_hidden, processed_dt,
           flagged_relevant, flagged_irrelevant)

out <- staging_candidates %>%
    filter(processed_dt >= lubridate::ymd(20220101)) %>%
    left_join(prod_labs %>% group_by(article_guid) %>%
              summarise(flagged_irrelevant = any(flagged_irrelevant),
                        flagged_relevant = !any(flagged_irrelevant)),
              by = "article_guid") %>%
    mutate(flagged_relevant = flagged_relevant & ofcr_cand) %>%
    filter(sent_cand, flagged_relevant | flagged_irrelevant) %>%
    transmute(article_guid,
              text = paste(title, content, sep = ""),
              relevant = flagged_relevant) %>%
    mutate(relevant = if_else(relevant, "a_relevant", "b_norelevant"))

write_parquet(out, args$output)

# note: required for generating new classifications/reviewing existing
staging_candidates %>%
    mutate(text = paste(title, content, sep = "")) %>%
    select(-title, -content) %>%
    distinct(article_guid, article_id, text, sent_cand, ofcr_cand) %>%
    write_parquet("output/all-candidates.parquet") %>%
    invisible()

# done.
