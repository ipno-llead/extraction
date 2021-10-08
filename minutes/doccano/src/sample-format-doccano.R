# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# libs{{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    jsonlite,
    purrr,
    readr,
    stringr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../extract/export/output/hearings.parquet")
parser$add_argument("--meta", default = "../import/export/output/metadata.csv")
parser$add_argument("--sentdir", default = "frozen/sent")
parser$add_argument("--outputdir", default="output")
args <- parser$parse_args()
# }}}

# conversion helpers {{{
l2json <- function(l) {
    metas <- names(l)[names(l) != "text"]
    list(
        meta = l[metas],
        text = l[["text"]]
    ) %>% toJSON(auto_unbox=TRUE)
}
# }}}

docs <- read_parquet(args$input)
dict <- read_delim(args$meta, delim = "|",
                   col_types = cols(.default = col_character())) %>%
    distinct(fileid, db_path)

# note: previous exports did NOT include docid or hrgno,
# only fileid + page from/to
# exports should include info for identifying the chunk in the data
# (docid+hrgno, fileid+hrg_loc)
# remove previously labeled {{{
already <- tibble(inputfile = list.files(args$sentdir,
                              pattern = "*.jsonl",
                              full.names = TRUE)) %>%
    mutate(data = map(inputfile, readLines)) %>%
    unnest(data) %>%
    mutate(data = map(data, fromJSON)) %>%
    mutate(fileid = map_chr(data, "fileid"),
           doc_pg_from = map_chr(data, "doc_pg_from") %>% as.integer,
           doc_pg_to = map_chr(data, "doc_pg_to") %>% as.integer,
           text = map_chr(data, "text")) %>%
    select(-data, -inputfile)

# to remove
removes <- docs %>%
    transmute(docid, fileid, doc_pg_from, doc_pg_to,
              hrgno, hrg_pg_from, hrg_pg_to,
              text = paste(hrg_head, hrg_text, sep = "\n") %>% str_squish) %>%
    inner_join(already, by = c("fileid", "doc_pg_from", "doc_pg_to")) %>%
    filter(str_squish(text.x) == str_squish(text.y)) %>%
    distinct(docid, hrgno)
# }}}

samps <- docs %>%
    filter(hrg_type %in% c("police")) %>%
    anti_join(removes, by = c("docid", "hrgno"))

formatted <- samps %>%
    inner_join(dict, by = "fileid") %>%
    mutate(text = paste(hrg_head,
                        str_replace_all(hrg_text, "\n", " ") %>% str_squish,
                        sep = "\n")) %>%
    select(fileid, docid, hrgno, hrg_loc,
           jurisdiction, db_path,
           doc_pg_from, doc_pg_to,
           mtg_year, mtg_month, mtg_day,
           text) %>%
    mutate(json = pmap(., list) %>% map_chr(toJSON, auto_unbox = TRUE))

fl <- "output/doccano-json/sample-20211007.jsonl"
if (file.exists(fl)) file.remove(fl)
walk(formatted$json, cat, "\n", file = fl, append = TRUE)

# done.
