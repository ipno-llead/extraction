# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    readr,
    tidyr,
    writexl
)

parser <- ArgumentParser()
parser$add_argument("--input", default = "../export/output/minutes.parquet")
parser$add_argument("--overweight", type = "integer", default = 3L)
parser$add_argument("--sampsize", type = "integer", default = 40L)
parser$add_argument("--output")
args <- parser$parse_args()

docs <- read_parquet(args$input)

n_region <- length(unique(docs$f_region))
samps_region <- ceiling(.5 * args$sampsize/n_region)

sampled <- docs %>% group_by(f_region, docid) %>%
    summarise(has_hrg = any(!is.na(hrgno)), .groups="drop") %>%
    mutate(weight = if_else(has_hrg, args$overweight, 1L)) %>%
    nest(data = c(-f_region, -has_hrg)) %>%
    mutate(sampsize = pmin(map_int(data, nrow), samps_region)) %>%
    mutate(data = map2(data, sampsize, sample_n, weight=weight)) %>%
    unnest(data) %>% ungroup %>% distinct(f_region, docid, has_hrg)

out <- unique(sampled$docid)

writeLines(out, args$output)

# done.
