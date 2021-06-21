# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

# libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    readr,
    tidyr,
    writexl
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../export/output/minutes.parquet")
parser$add_argument("--already", default = "frozen")
parser$add_argument("--overweight", type = "integer", default = 3L)
parser$add_argument("--sampsize", type = "integer", default = 40L)
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

already <- list.files(args$already, full.names = TRUE) %>%
    map(readLines) %>% unlist %>% unique

docs <- read_parquet(args$input)

already_groups <- docs %>% filter(docid %in% already) %>%
    distinct(f_region, docid, doctype) %>%
    count(f_region, doctype, name = "region_samps")

n_grps <- nrow(distinct(docs, f_region, doctype)) - nrow(already_groups)
samps_grp <- ceiling(args$sampsize/n_grps)

sampled <- docs %>%
    distinct(docid, f_region, doctype) %>%
    anti_join(already_groups, by = c("f_region", "doctype")) %>%
    nest(data = -f_region) %>%
    mutate(sampsize = pmin(map_int(data, nrow), samps_grp)) %>%
    mutate(data = map2(data, sampsize, sample_n)) %>%
    unnest(data) %>% distinct(f_region, docid)

out <- unique(sampled$docid)

writeLines(out, args$output)

# done.
