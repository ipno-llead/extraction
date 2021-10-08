# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

pacman::p_load(
    argparse,
    arrow,
    dplyr,
    jsonlite,
    purrr,
    qpdf,
    readr,
    tidyr
)


parser <- ArgumentParser()
parser$add_argument("--input", default = "../extract/export/output/hearings.parquet")
parser$add_argument("--doctypes", default = "../classify-pages/export/output/minutes.parquet")
parser$add_argument("--meta", default = "../import/export/output/metadata.csv")
parser$add_argument("--sampsize", type="integer", default=100L)
parser$add_argument("--outputdir", default="output")
args <- parser$parse_args()

l2json <- function(l) {
    metas <- names(l)[names(l) != "text"]
    list(
        meta = l[metas],
        text = l[["text"]]
    ) %>% toJSON(auto_unbox=TRUE)
}


docs <- read_parquet(args$input)
doctypes <- read_parquet(args$doctypes) %>% distinct(docid, doctype)

dict <- read_delim(args$meta, delim = "|",
                   col_types = cols(.default = col_character())) %>%
    distinct(fileid, db_path)

samps <- docs %>%
    inner_join(doctypes, by = "docid") %>%
    filter(hrg_type != "fire",
           !str_detect(hrg_text, regex("employed by the (.+) fire department",
                                       ignore_case = TRUE))) %>%
    nest(data = c(-doctype, -jurisdiction, -hrg_type)) %>%
    #     filter(hrg_type == "unknown") %>% mutate(data = map(data, sample_n, 1)) %>%
    #     unnest(data) %>%
    #     select(hrg_head, hrg_text)
    mutate(sampsize = pmin(map_int(data, nrow), 10)) %>%
    mutate(data = map2(data, sampsize, sample_n)) %>%
    unnest(data) %>%
    select(docid, hrgno)

formatted <- docs %>%
    inner_join(samps, by = c("docid", "hrgno")) %>%
    mutate(text = paste(hrg_head,
                        str_replace_all(hrg_text, "\n", " ") %>% str_squish,
                        sep = "\n")) %>%
    inner_join(dict, by = "fileid") %>%
    select(fileid, jurisdiction, db_path, doc_pg_from, doc_pg_to, text) %>%
    mutate(json = pmap(., list) %>% map_chr(toJSON, auto_unbox = TRUE))
#     mutate(json = pmap(., list),
#            json = map_chr(json, l2json))


fl <- "output/doccano-json/sample-20210719.jsonl"
if (file.exists(fl)) file.remove(fl)
walk(formatted$json, cat, "\n", file = fl, append = TRUE)

    pluck("json", 1)
    "["(1, ) %>%
    toJSON(pretty=F) %>% writeLines("output/text/doccano-test.jsonl")

writeLines(tmp$text[1] %>% str_replace_all("\n", "\\n"), "output/text/doccano-test.txt")

subsets <- samps %>%
    group_by(input=filename) %>%
    summarise(pages=list(pageno), .groups='drop') %>%
    mutate(output=paste0(args$outputdir, "/", basename(input))) %>%
    mutate(subsetted_file=pmap_chr(., pdf_subset))

pdf_combine(subsets$subsetted_file,
            output=paste0(args$outputdir, "/", "sampled.pdf"))

# done.
