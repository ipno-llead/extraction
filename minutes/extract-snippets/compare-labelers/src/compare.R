# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../import/output/irr-review.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

library(arrow)
library(tidyverse)
library(fs)

labs <- dir_ls("../import/output/training") %>%
    set_names(path_file) %>% set_names(path_ext_remove) %>%
    map(read_parquet) %>%
    map_dfr(distinct, labeler, fileid, text, start, end, label)


    # 
    # all_labs <- labs %>%
    #     select(hrgno,
    #            docid,
    #            all_of(xtra_id_fields),
    #            labeler,
    #            start = labstart,
    #            end = labend,
    #            label) %>% distinct %>%
    #     arrange(labeler, docid, hrgno,
    #             fileid, doc_pg_from, doc_pg_to, hrgloc,
    #             start, label) %>%
    #     group_by(labeler, docid, hrgno,
    #             fileid, doc_pg_from, doc_pg_to, hrgloc) %>%
    #     mutate(label_seqid = seq_along(label)) %>%
    #     ungroup
    # 
    # all_labs %>%
    #     distinct(docid, hrgno, labeler) %>%
    #     inner_join(distinct(all_labs, docid, hrgno, labeler),
    #                by = c("docid", "hrgno")) %>%



overlap_setup <- labs %>%
    full_join(labs, by = c("fileid", "text"),
              suffix = c("1", "2")) %>%
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
    group_by(label = value)

# tagged the same location, was it the same tag?
overlap_setup %>%
    filter(overlap_pct > 0) %>%
    group_by(fileid, text, label1) %>%
    mutate(label_agree = if_else(any(label_agree), "agree", "disagree")) %>%
    ungroup %>%
    count(label1, label_agree) %>%
    pivot_wider(names_from = label_agree, values_from = n) %>%
    mutate(pct = agree/(agree+disagree)) %>%
    arrange(desc(agree + disagree)) %>% print(n=Inf)

    group_by(label1) %>% filter(sum(n) > 20) %>% ungroup %>%
    filter(label2 %in% label1) %>%
    pivot_wider(names_from = label2, values_from =n)

    mutate(overlapping = overlap_pct > .1) %>%
    group_by(fileid, text, label1) %>%
    summarise(any_labeled = any(label_agree),
              overlapping_agree = any(overlapping & label_agree)) %>%
    #     filter(label1 == "accused_officer_name", !any_labeled)
    ungroup %>%
    #     mutate()
    count(label1, any_labeled, overlapping_agree)


overlap_setup %>%
    mutate(overlapping = overlap_pct > .1) %>%
    filter(overlapping | label_agree)
















overlaps %>%
    mutate(label_agree = if_else(label_agree, "agree", "disagree")) %>%
    group_by
    count(label1, label_agree) %>%
    pivot_wider(names_from = label_agree, values_from = n) %>%
    mutate(agree_pct = agree/(agree+disagree))


    group_by(docid, hrgno, labeler1, labeler2, label_seqid1) %>%
    filter(overlap_pct == max(overlap_pct)) %>%
    ungroup

all_overlaps %>%
    filter(labeler1 < labeler2) %>%
    mutate(overlap = if_else(label1 != label2, 0, overlap)) %>%
    group_by(labeler1, docid, hrgno, label_seqid1, label1, labeler2) %>%
    summarise(overlap = sum(overlap), max_overlap = max(max_overlap),
              .groups = "drop") %>%
    group_by(label1) %>% summarise(overlap = sum(overlap) / sum(max_overlap))

labs %>% filter(label == "appeal_denied") %>% group_by(docid, hrgno) %>% filter(n_distinct(labeler) > 1) %>%
    ungroup %>% arrange(docid, hrgno, start) %>%
    filter(docid == "0236e725") %>%
    select(labeler, docid, snippet)

labs %>%
    filter(str_detect(label, "appeal_")) %>%
    group_by(docid, hrgno) %>% filter(n_distinct(label) > 1, n_distinct(labeler) > 1) %>%
    ungroup %>% arrange(docid, hrgno, labeler) %>%
    select(docid, hrgno, labeler, snippet, label) %>% pluck("snippet")

all_overlaps %>% filter(label1 != label2) %>%
    select(label1, labeler1, label2, labeler2, overlap_pct, start1, start2, end1, end2)

all_overlaps %>%
    filter(docid == "0a45da75", hrgno == 3)
    group_by(labeler1, docid, hrgno, label_seqid1, labeler2) %>%
    filter(n() > 1)


all_labs %>% filter(docid == "1309351c")
