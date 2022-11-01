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
parser$add_argument("--scores")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

scores <- read_parquet(args$scores)

out <- scores %>%
    filter(sent_cand) %>%
    transmute(article_id, article_guid,
              score = score_a_relevant,
              relevant = if_else(score > .5, "relevant", "not_relevant")) %>%
    arrange(desc(score))

write_csv(out, args$output)

# done.
