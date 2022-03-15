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
    tidyr
)
# }}}

# i neglected to include the docid on the samples, need fileid+pgs to retrieve
INDEX <- read_parquet("../classify-pages/export/output/minutes.parquet") %>%
    group_by(docid, fileid) %>%
    summarise(doc_pg_from = min(pageno), doc_pg_to = max(pageno),
              .groups = 'drop')

process <- function(labs, index = INDEX) {
    fid <- labs$fileid
    # wamp wamp
    #doc <- labs$docid
    from <- labs$doc_pg_from
    to <- labs$doc_pg_to
    docid <- filter(index,
                    fileid == fid,
                    doc_pg_from == from,
                    doc_pg_to == to) %>% pluck("docid")
    txt <- labs$data
    labels <- labs$label
    if (length(labels) < 1)
        return(tibble(docid = docid,
                      snippet = NA_character_,
                      label = NA_character_))
    substrings <- str_sub(txt, start = labels[,1], end = labels[,2]) %>%
        str_trim
    tibble(docid = docid, hrgno = labs$hrgno, snippet = substrings, label = labels[,3])
}

imported_data <- tibble(inputfile = list.files("input/phase1/",
                              pattern = "*.jsonl",
                              full.names = TRUE,
                              recursive = FALSE)) %>%
    mutate(data = map(inputfile, readLines)) %>%
    unnest(data) %>%
    mutate(data = map(data, fromJSON)) %>%
    filter(map_int(data, length) == 14)

processed <- imported_data %>%
    #     head(3) %>%
    #     mutate(fid = map(data, "fileid")) %>%
    #     filter(!map_lgl(fid, is.null)) %>% pluck("data", 1)
    mutate(data = map(data, process)) %>%
    unnest(data) %>% distinct(docid, hrgno, inputfile, label, snippet)

processed %>%
    group_by(docid, hrgno) %>%
    mutate(mult = n_distinct(label) > 1) %>%
    ungroup %>% distinct(mult, docid, hrgno) %>%
    group_by(mult) %>% summarise(n = n())

    #     group_by(label) %>% summarise(n_doc = n_distinct(docid)) %>% arrange(desc(n_doc))
    select(-inputfile) %>%
    count(label, sort=T)
    sample_frac(1) %>% print(n=25)


mults <- processed %>%
    group_by(docid) %>%
    summarise(mult = n_distinct(inputfile) > 1, .groups = "drop")

processed %>% distinct(docid)
processed %>% filter(label == "irrelevant_document") %>%
    distinct(docid)

processed %>%
    inner_join(mults, by = "docid") %>%
    filter(mult) %>%
    #     filter(mult, label == "initial_discipline") %>%
    arrange(docid, label, inputfile) %>%
    nest(-docid) %>% sample_n(1)
    group_by(label) %>%
    summarise(ndoc = n_distinct(docid),
              nrev = n_distinct(inputfile))
              nmult = sum(mult))
    group_by(docid) %>% filter(n_distinct(inputfile) > 1) %>%
    filter(label == "accused_officer_name") %>% ungroup %>% arrange(docid) %>%
    group_by(docid) %>% filter(n_distinct(snippet) > 1)
