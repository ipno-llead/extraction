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
parser$add_argument("--input", default = "../import/output/phase2.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

labs <- read_parquet(args$input) %>% filter(!is.na(docid))

all_labs <- distinct(labs, hrgno, docid, labeler, start, end, label) %>%
    arrange(labeler, docid, hrgno, start, label) %>%
    group_by(labeler, docid, hrgno) %>%
    mutate(label_seqid = seq_along(label)) %>%
    ungroup
    #     ungroup %>%
    #     arrange(labeler, docid, hrgno, start) %>%
    #     group_by(labeler, docid, hrgno) %>%
    #     mutate(newitem = (label != lag(label, default = "NOPE")) |
    #            start > lag(end) + 25) %>%
    #     replace_na(list(newitem = FALSE)) %>%
    #     mutate(label_seqid = cumsum(newitem)) %>%
    #     ungroup %>% select(-newitem)

all_labs %>%
    distinct(docid, hrgno, labeler) %>%
    inner_join(distinct(all_labs, docid, hrgno, labeler),
               by = c("docid", "hrgno")) %>%



all_overlaps <- all_labs %>%
    full_join(all_labs, by = c("docid", "hrgno"),
              suffix = c("1", "2")) %>%
    filter(labeler1 != labeler2) %>%
    mutate(start_off = abs(start2 - start1),
           overlap = pmax(0, pmin(end1, end2) - pmax(start1, start2)),
           max_overlap = pmax(end2 - start2, end1 - start1),
           overlap_pct = overlap / max(overlap)) %>%
    filter(overlap_pct > 0) %>%
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
