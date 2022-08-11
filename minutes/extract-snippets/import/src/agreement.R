# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2022, HRDAG, GPL v2 or later
# =========================================

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    assertr,
    dplyr,
    fs,
    purrr,
    stringr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--inputs", default = "output/training/phase1.parquet output/training/phase2.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

paths <- fs::as_fs_path(flatten_chr(str_split(args$inputs, " "))) %>%
    set_names(path_ext_remove)
stopifnot(all(file_exists(paths)))

all_labs <- map_dfr(paths, read_parquet, .id = "session") %>%
    filter(labeler != "unknown")

labtxt <- all_labs %>% distinct(fileid, text, start, end, labeler, label)

overlap_setup <- labtxt %>%
    inner_join(labtxt, by = c("fileid", "text"), suffix = c("1", "2")) %>%
    filter(labeler1 < labeler2) %>%
    mutate(start_off = abs(start2 - start1),
           overlap = pmax(0, pmin(end1, end2) - pmax(start1, start2)),
           max_overlap = pmax(end2 - start2, end1 - start1),
           overlap_pct = overlap / max_overlap) %>%
    mutate(label_agree = label1 == label2) %>%
    select(-start_off, -overlap, -max_overlap,
           -start1, -end1, -start2, -end2)

# someone tagged the same category, but in a different location
overlap_setup %>%
    filter(label_agree & overlap_pct <= .01) %>%
    distinct(fileid, text, label1) %>%
    pivot_longer(cols = c(label1)) %>%
    group_by(label = value) %>% summarise(n = n()) %>% arrange(desc(n))

possible_overlaps <- function(labdata) {
    keys <- distinct(labdata, fileid, text, labeler)
    keys %>%
        inner_join(keys, by = c("fileid", "text"), suffix = c("1", "2")) %>%
        filter(labeler1 < labeler2) %>%
        select(fileid, text, labeler1, labeler2) %>%
        distinct
}

possible_labels <- function(labdata) {
    distinct(labdata, fileid, text, label)
}

overlaps <- possible_overlaps(labtxt) %>%
    full_join(possible_labels(labtxt), by = c("fileid", "text")) %>%
    filter(!is.na(labeler1) | !is.na(labeler2)) %>%
    left_join(overlap_setup,
              by = c("fileid", "text", "labeler1", "labeler2")) %>%
    verify(!is.na(label1) & !is.na(label2) &
           !is.na(overlap_pct) & !is.na(label_agree)) %>%
    verify(labeler1 < labeler2) %>%
    filter(overlap_pct > .2 | label_agree)

# tagged the same location, was it the same tag?
overlaps %>%
    group_by(fileid, text, label, labeler1, labeler2) %>%
    #     filter(overlap_pct > .2 | !any(overlap_pct > .2)) %>%
    #     mutate(label_agree = case_when(
    #         any(label_agree & overlap_pct > .2) ~ "agree",
    #         
    #                                    ))
    mutate(label_agree = if_else(any(label_agree & overlap_pct > .2),
                                 "agree", "disagree")) %>%
    ungroup %>%
    mutate(hrg = paste0(fileid, text),
           snippet = paste0(fileid, text, label)) %>%
    group_by(label, label_agree) %>%
    summarise(n_docs = n_distinct(hrg),
              n_labelers = length(unique(c(labeler1, labeler2))),
              n_snippets = n_distinct(snippet)) %>%
    group_by(label) %>%
    mutate(n_docs = sum(n_docs),
           n_labelers = median(n_labelers)) %>%
    pivot_wider(names_from = label_agree, values_from = n_snippets) %>%
    mutate(pct = agree/(agree+disagree)) %>%
    arrange(desc(pct)) %>% print(n=Inf)

