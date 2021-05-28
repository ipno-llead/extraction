# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    stringr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../../classify-pages/export/output/minutes.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

docs <- read_parquet(args$input)

doclines <- docs %>%
    arrange(fileid, pageno) %>%
    group_by(docid) %>% mutate(docpg = seq_along(text)) %>%
    mutate(text = str_split(text, "\n"),
           lineno = map(text, ~seq_along(.))) %>%
    unnest(c(text, lineno)) %>%
    mutate(text = str_squish(text)) %>% filter(text != "") %>% ungroup

write_parquet(doclines, args$output)

# done.
