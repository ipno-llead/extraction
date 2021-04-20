# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    qpdf,
    readr,
    tidyr
)


parser <- ArgumentParser()
parser$add_argument("--input", default="../ocr/output/minutes.parquet")
parser$add_argument("--index", default="../ocr/output/index.csv")
parser$add_argument("--ents", default="../eda/output/matched-entities.parquet")
parser$add_argument("--sampsize", type="integer", default=5L)
parser$add_argument("--outputdir", default="output")
args <- parser$parse_args()

docs <- read_parquet(args$input)
ents <- read_parquet(args$ents)
index <- read_delim(args$index, delim="|",
                    col_types=cols(.default=col_character()))

samps <- docs %>%
    distinct(fileid, filename, pageno) %>%
    mutate(region=strsplit(filename, "/"),
           region=map_chr(region, 6)) %>%
    left_join(distinct(ents, fileid, pageno=pg, ent=T),
              by=c("fileid", "pageno")) %>%
    replace_na(list(ent=F)) %>%
    nest(data=c(-region, -ent)) %>%
    mutate(sampled=map(data, sample_n, args$sampsize)) %>%
    select(sampled) %>% unnest(sampled)

proc <- function(txt) {
    str_split(txt, "\n{2,}")[[1]] %>%
        keep(str_count(., "[a-zA-Z]") > 2) %>%
        str_replace_all("\n", " ") %>%
        paste(collapse="\n\n")
}

dict <- index %>% mutate(fileid=str_sub(filesha1, 1, 7)) %>%
    distinct(fileid, db_path)

l2json <- function(l) {
    metas <- names(l)[names(l) != "text"]
    list(
        meta=l[metas],
        text=l[["text"]]
    ) %>% toJSON(auto_unbox=TRUE)
}

tmp <- docs %>%
    select(-filename) %>%
    inner_join(distinct(samps, fileid, pageno),
               by=c("fileid", "pageno")) %>%
    mutate(text=map_chr(text, proc)) %>%
    inner_join(dict, by="fileid") %>%
    select(fileid, db_path, pageno, text) %>%
    mutate(json=pmap(., list),
           json=map_chr(json, l2json))


fl <- "output/text/doccano-test.jsonl"
file.remove(fl)
file.create(fl)

# con <- file("output/text/doccano-test.jsonl")
# for (i in 1:nrow(tmp)) cat(tmp$json[i], "\n", file=fl, append=TRUE)
walk(tmp$json, cat, "\n", file="output/text/doccano-test.jsonl", append=TRUE)
# close(con)

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
