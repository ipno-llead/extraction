# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs{{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    logger,
    purrr,
    stringr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../classify/output/minutes.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

docs <- read_parquet(args$input) %>% arrange(docid, docpg, lineno)

log_info("read ", nrow(docs), " rows of input data")
log_info(length(unique(docs$docid)), " documents")

hearing_numbers <- docs %>%
    filter(linetype %in% c("hearing_header", "hearing")) %>%
    group_by(docid) %>%
    mutate(newhearing = linetype == "hearing_header" &
           lag(linetype, default = "START") != "hearing_header",
       hrgno = cumsum(newhearing)) %>%
    ungroup %>%
    distinct(docid, docpg, lineno, hrgno)

log_info(distinct(hearing_numbers, docid, hrgno) %>% nrow,
         " distinct hearings")

out <- docs %>%
    left_join(hearing_numbers,
              by = c("docid", "docpg", "lineno")) %>%
    arrange(docid, docpg, lineno)

log_info("# of hearings identified by jurisdiction: ")

out %>%
    filter(!is.na(hrgno)) %>%
    distinct(docid, jurisdiction = f_region, hrgno) %>%
    count(jurisdiction) %>% print

log_info("writing ", nrow(out), " rows to output")

write_parquet(out, args$output)

# done.