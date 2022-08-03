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
    dplyr,
    purrr,
    stringr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--phase1", default = "output/phase1-all-labels.parquet")
parser$add_argument("--phase2", default = "output/phase2-all-labels.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

combined <- list(phase1 = args$phase1, phase2 = args$phase2) %>%
    map_dfr(read_parquet, .id = "phase") %>%
    filter(str_count(sentence, "[A-Za-z]") > 4)

no_docid <- combined %>% filter(is.na(docid))
ok <- combined %>% filter(!is.na(docid))

xref <- ok %>%
    group_by(fileid, doc_pg_from, doc_pg_to) %>%
    filter(n_distinct(docid) == 1, n_distinct(hrgno) == 1) %>%
    ungroup %>%
    distinct(fileid, doc_pg_from, doc_pg_to, docid, hrgno)

salvaged <- no_docid %>%
    select(-docid, -hrgno, -hrgloc) %>%
    inner_join(xref, by = c("fileid", "doc_pg_from", "doc_pg_to"))

all_labs <- bind_rows(ok, salvaged)

labs_out <- all_labs %>%
    distinct(docid, hrgno, sentence_id, sentence, label) %>%
    group_by(docid, hrgno,
             sentence_id, sentence) %>%
    summarise(label = paste(label, collapse = " ") %>% str_trim,
              .groups = "drop") %>%
    mutate(validation = runif(nrow(.)) > .6)

write_parquet(labs_out, args$output)

# pairs for irr review:

all_labs %>%
    distinct(docid, hrgno, sentence_id, sentence,
             labeler, label, labstart, labend)

write_parquet(all_labs, "output/irr-review.parquet")

# done.
