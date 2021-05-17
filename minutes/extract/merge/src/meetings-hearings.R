# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

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
parser$add_argument("--meetings", default = "../import/output/minutes.parquet")
parser$add_argument("--dates", default = "../meeting-dates/output/mtg-dates.parquet")
parser$add_argument("--hearingtypes", default = "../classify-hearings/output/hrg-class.parquet")
parser$add_argument("--accused", default = "../hearing-accused/output/hrg-accused.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

docs <- read_parquet(args$meetings)
mtg_date <- read_parquet(args$dates)
hrg_tp <- read_parquet(args$hearingtypes)
hrg_acc <- read_parquet(args$accused)

# hearings {{{
hrgs <- docs %>%
    filter(!is.na(hrgno)) %>%
    arrange(docid, docpg, hrgno, lineno) %>%
    group_by(docid, hrgno, linetype) %>%
    summarise(text = paste(text, collapse="\n"),
              .groups="drop") %>%
    pivot_wider(names_from = linetype, values_from = text) %>%
    select(docid, hrgno, hrg_head = hearing_header, hrg_text = hearing)

doc_xref <- docs %>% group_by(docid) %>%
    mutate(doc_pg_from = min(pageno), doc_pg_to = max(pageno)) %>%
    group_by(docid, hrgno) %>%
    mutate(hrg_pg_from = min(pageno), hrg_pg_to = max(pageno)) %>%
    ungroup %>%
    distinct(docid, hrgno, doc_pg_from, doc_pg_to, hrg_pg_from, hrg_pg_to) %>%
    filter(!is.na(hrgno))
# }}}

out <- doc_xref %>%
    left_join(mtg_date, by = "docid") %>%
    left_join(hrg_tp, by = c("docid", "hrgno")) %>%
    left_join(hrg_acc, by = c("docid", "hrgno")) %>%
    left_join(hrgs, by = c("docid", "hrgno")) %>%
    select(docid, hrgno, starts_with("mtg_"),
           starts_with("hrg_"))

write_parquet(out, args$output)

# done.