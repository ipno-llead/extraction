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
parser$add_argument("--meetings")
parser$add_argument("--dates")
parser$add_argument("--hearingtypes")
parser$add_argument("--accused")
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
    group_by(fileid, docid, hrgno) %>%
    mutate(hrg_loc = paste(min(line_seqid), max(line_seqid), sep = ":")) %>%
    group_by(fileid, docid, hrgno, hrg_loc, linetype) %>%
    summarise(text = paste(text, collapse="\n"),
              .groups="drop_last") %>%
    pivot_wider(names_from = linetype, values_from = text) %>%
    select(fileid, docid, hrgno, hrg_loc,
           hrg_head = hearing_header, hrg_text = hearing)

doc_xref <- docs %>% group_by(docid) %>%
    mutate(fileid = unique(fileid),
           jurisdiction = unique(f_region),
           doc_pg_from = min(pageno),
           doc_pg_to = max(pageno)) %>%
    group_by(docid, hrgno) %>%
    mutate(hrg_pg_from = min(pageno), hrg_pg_to = max(pageno)) %>%
    ungroup %>%
    distinct(docid, fileid, jurisdiction,
             doc_pg_from, doc_pg_to,
             hrgno, hrg_pg_from, hrg_pg_to) %>%
    filter(!is.na(hrgno))
# }}}

out <- doc_xref %>%
    left_join(mtg_date, by = "docid") %>%
    left_join(hrg_tp, by = c("docid", "hrgno")) %>%
    left_join(hrg_acc, by = c("docid", "hrgno")) %>%
    left_join(hrgs, by = c("fileid", "docid", "hrgno")) %>%
    select(docid, fileid, jurisdiction,
           starts_with("doc_"),
           starts_with("mtg_"),
           hrgno,
           starts_with("hrg_"))

write_parquet(out, args$output)

# done.
