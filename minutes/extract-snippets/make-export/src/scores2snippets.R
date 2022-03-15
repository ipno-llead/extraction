# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    assertr,
    dplyr,
    stringr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--scores", default = "../generic-models/output/hrg-snippet-scores.parquet")
parser$add_argument("--dockets", default = "../docketnums/output/hearings-dockets.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# one column that "scores" no-label, not used
scores <- read_parquet(args$scores) %>% select(-score_)
dockets <- read_parquet(args$dockets)

LABELS <- c("appeal_denied", "incident_summary",
            "initial_charges", "initial_discipline")

predicted <- scores %>%
    pivot_longer(cols = starts_with("score"),
                 names_to = "type", values_to = "score") %>%
    filter(score >= .5) %>%
    mutate(type = str_replace(type, "score_", "")) %>%
    verify(type %in% LABELS) %>%
    select(docid, hrgno, type, snippet = sentence) %>% distinct %>%
    group_by(docid, hrgno, type) %>%
    summarise(snippet = paste(snippet, collapse = " "),
              .groups = "drop")

out <- predicted %>%
    full_join(dockets, by = c("docid", "hrgno")) %>%
    pivot_wider(names_from = type, values_from = snippet) %>%
    select(docid, hrgno, docket, !!!LABELS)

stopifnot(nrow(out) == nrow(distinct(out, docid, hrgno)))

write_parquet(out, args$output)

# done.
