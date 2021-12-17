# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# note: wanted to send already-sent samples to sukari to upload for volunteers
# first batch had neglected to put docid and hearing id.
#       but it included pagenumbers etc. to do that identification
# this is a temp hack to put the identifiers back on

pacman::p_load(jsonlite, tidyverse, arrow, assertr)
path <- "frozen/sent/sample-20210719.jsonl"
#meta <- "../import/export/output/metadata.csv"
hearings <- "../extract/export/output/hearings.parquet" %>% read_parquet


js <- tibble(inputfile = path) %>%
    mutate(data = map(inputfile, readLines)) %>%
    unnest(data) %>%
    mutate(data = map(data, fromJSON)) %>%
    mutate(fileid = map_chr(data, "fileid"),
           db_path = map_chr(data, "db_path"),
           doc_pg_from = map_chr(data, "doc_pg_from") %>% as.integer,
           doc_pg_to = map_chr(data, "doc_pg_to") %>% as.integer,
           text = map_chr(data, "text")) %>%
    select(-data, -inputfile)

out <- hearings %>%
    transmute(fileid, docid, hrgno, hrg_loc,
              jurisdiction,
              doc_pg_from, doc_pg_to,
              hrg_pg_from, hrg_pg_to,
              mtg_year, mtg_month, mtg_day,
              text = paste(hrg_head, hrg_text, sep = "\n")) %>%
    inner_join(js, by = c("fileid", "doc_pg_from", "doc_pg_to")) %>%
    filter(str_squish(text.x) == str_squish(text.y)) %>%
    verify(nrow(.) == 76) %>%
    rename(text = text.x) %>% select(-text.y) %>%
    mutate(text = str_replace_all(text, "\n", " ") %>% str_squish) %>%
    select(fileid, docid, hrgno, hrg_loc,
           jurisdiction, db_path,
           doc_pg_from, doc_pg_to,
           mtg_year, mtg_month, mtg_day,
           text) %>%
    mutate(json = pmap(., list) %>% map_chr(toJSON, auto_unbox = TRUE))

fl <- "output/doccano-json/sample-20210719-withid.jsonl"
if (file.exists(fl)) file.remove(fl)
walk(out$json, cat, "\n", file = fl, append = TRUE)


