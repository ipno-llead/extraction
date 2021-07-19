# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    readr,
    tidyr
)


parser <- ArgumentParser()
parser$add_argument("--input", default = "../classify-pages/export/output/minutes.parquet")
# parser$add_argument("--meta", default = "../import/export/output/metadata.csv")
parser$add_argument("--sampsize", type="integer", default=100L)
parser$add_argument("--outputdir", default="output")
args <- parser$parse_args()

l2json <- function(l) {
    metas <- names(l)[names(l) != "text"]
    list(
        meta = l[metas],
        text = l[["text"]]
    ) %>% toJSON(auto_unbox=TRUE, pretty = TRUE)
}


docs <- read_parquet(args$input)
doctypes <- read_parquet(args$doctypes) %>% distinct(docid, doctype)

samps <- docs %>%
    inner_join(doctypes, by = "docid") %>%
    filter(hrg_type %in% c("police")) %>%
    nest(data = -doctype) %>%
    mutate(data = map(data, sample_n, 15)) %>%
    unnest(data) %>%
    select(docid, hrgno)

# meta <- read_delim(args$meta, delim = "|",
#     col_types = cols(.default = col_character(),
#                      year = col_integer(),
#                      month = col_integer(),
#                      day = col_integer()))
# 

formatted <- docs %>%
    inner_join(samps, by = c("docid", "hrgno")) %>%
    mutate(text = paste(hrg_head, hrg_text, sep = "\n")) %>%
    inner_join(dict, by = "fileid") %>%
    select(fileid, jurisdiction, db_path, doc_pg_from, doc_pg_to,
           mtg_year, mtg_month, mtg_day, text) %>%
    mutate(json = pmap(., list),
           json = map_chr(json, l2json))

fl <- "output/doccano-json/sample-20210719.jsonl"
if (file.exists(fl)) file.remove(fl)
walk(formatted$json, cat, "\n", file = fl, append = TRUE)


