# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    jsonlite,
    purrr,
    stringr,
    tools
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--inputdir", default = "output/jsonl/phase1")
parser$add_argument("--hearings", default = "../../extract/export/output/hearings.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# process json files {{{
process_file <- function(filename){
    readLines(filename) %>% map(fromJSON) %>%
        map_dfr(process_js)
}

process_js <- function(js) {
    fid <- js$fileid
    docid <- js$docid
    from <- js$doc_pg_from
    to <- js$doc_pg_to
    txt <- js$data %>% str_to_lower %>% str_squish
    labels <- js$label
    if (length(labels) < 1)
        return(tibble(docid = docid,
                      snippet = NA_character_,
                      label = NA_character_))
    labstarts <- as.integer(labels[,1])
    labends <- as.integer(labels[,2])
    substrings <- str_sub(txt, start = labstarts, end = labends) %>%
        str_trim
    tibble(docid = docid,
           fileid = fid,
           doc_pg_from = from,
           doc_pg_to = to,
           hrgno = js$hrgno,
           text = txt,
           start = labstarts,
           end = labends,
           snippet = substrings,
           label = labels[,3])
}
# }}}


hrgs <- read_parquet(args$hearings)
x <- read_parquet("output/hearings-dockets.parquet")

hrgs %>% left_join(x, by = c("docid", "hrgno")) %>%
    filter(trimws(docket) != "") %>%
    select(docid, hrgno, docket) %>% sample_n(10)

hrgs %>%
    mutate(text = str_to_lower(str_squish(paste(hrg_head, hrg_text)))) %>%
    mutate(dtct = str_detect(text, "docket"),
           xx = str_match_all(text, "docket ((no[^#0-9]{0,3})?)((\\W+.+\\W+){1,3})")) %>%
    #     unnest(xx) %>%
    select(docid, agency, hrgno, hrg_type, hrg_accused, dtct, xx) %>%
    filter(dtct) %>%
    mutate(xx = map(xx, ~.[,5])) %>% unnest(xx)


labs <- list.files(args$inputdir, full.names=TRUE, pattern = "*.jsonl") %>%
    set_names(~file_path_sans_ext(basename(.))) %>%
    map_dfr(process_file, .id = "labeler")

library(tidyr)
labs %>%
    filter(label == "docket_number") %>%
    mutate(dtct = str_detect(text, "docket"),
           xx = str_extract_all(text, "docket(\\W+.+\\W+){1,3}")) %>%
    unnest(xx) %>%
    select(xx)
    select
    distinct(fileid, doc_pg_from, doc_pg_to, snippet, ltext = text) %>%
    inner_join(hrgs %>%
                   transmute(fileid, docid, hrgno, doc_pg_from, doc_pg_to,
                             hrg_text = paste(hrg_head, hrg_text)) %>%
                   distinct,
               by = c("fileid", "doc_pg_from", "doc_pg_to")) %>%
    filter(fileid == "3f4551e") %>%
    mutate(dist = stringdist::stringdist(ltext, hrg_text, method = "cosine")) %>%
    group_by(docid, hrgno, snippet) %>% filter(dist <= min(dist)) %>%
    pluck("ltext", 1)
    ungroup %>%
    arrange(desc(dist)) %>%
    pluck("ltext", 1) %>% cat


write_parquet(labs, args$output)

# done.
