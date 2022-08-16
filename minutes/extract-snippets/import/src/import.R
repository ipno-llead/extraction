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
    jsonlite,
    logger,
    purrr,
    stringr,
    tools
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--inputdir", default = "output/jsonl/hearing-text-staging")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# process json files {{{
process_file <- function(filename){
    log_info(filename)
    readLines(filename) %>% map(fromJSON) %>%
        map_dfr(process_js)
}

process_js <- function(js) {
    fid <- js$fileid
    docid <- js$docid
    from <- js$doc_pg_from
    to <- js$doc_pg_to
    txt <- js$text
    labels <- js$label
    hrgloc <- js$hrg_loc
    if (length(labels) < 1)
        return(tibble(docid = docid,
                      snippet = NA_character_,
                      label = NA_character_))
    labstarts <- as.integer(labels[,1])
    labends <- as.integer(labels[,2])
    substrings <- str_sub(txt, start = labstarts, end = labends) %>%
        str_trim
    tibble(fileid = fid,
           docid = docid,
           doc_pg_from = from,
           doc_pg_to = to,
           hrgno = js$hrgno,
           hrgloc = hrgloc,
           text = txt,
           start = labstarts,
           end = labends,
           snippet = substrings,
           label = labels[,3])
}
# }}}

labs <- list.files(args$inputdir, full.names=TRUE, pattern = "*.jsonl") %>%
    set_names(~file_path_sans_ext(basename(.))) %>%
    map_dfr(process_file, .id = "labeler")

write_parquet(labs, args$output)

# done.

# distinct_hrgs <- labs %>% distinct(docid, hrgno)

# distinct(labs, docid, labeler) %>%
#     group_by(docid) %>% summarise(n_labelers = n_distinct(labeler)) %>%
#     count(n_labelers)
# 
# distinct(labs, docid, labeler) %>% count(labeler, sort=T)
# 
