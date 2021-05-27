# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

pacman::p_load(
    argparse,
    arrow,
    assertr,
    dplyr,
    here,
    purrr,
    qpdf,
    readr,
    stringr
)

parser <- ArgumentParser()
parser$add_argument("--hrgs", default = "../extract/export/output/hearings.parquet")
parser$add_argument("--meta", default = "../import/export/output/metadata.csv")
parser$add_argument("--outputdir", default = "output")
args <- parser$parse_args()

hrgs <- read_parquet(args$hrgs)
meta <- read_delim(args$meta, delim="|",
                   col_types = cols(.default = col_character())) %>%
    select(fileid, filepath)
pdfdir <- file.path(args$outputdir, "pdfs")
if (!dir.exists(pdfdir)) dir.create(pdfdir, recursive = TRUE)

make_pdf <- function(input, pages, output) {
    if (file.exists(output)) return(output)
    pdf_subset(input=input, pages=pages, output=output)
}

driver <- hrgs %>%
    filter(!is.na(hrg_acc_uid),
           hrg_type %in% c("police", "unknown")) %>%
    select(docid, fileid, doc_pg_from, doc_pg_to) %>%
    distinct %>%
    left_join(meta, by = "fileid") %>%
    mutate(filepath = str_replace(filepath, "^[^/]+/", ""),
           filepath = here::here(filepath))

subsetted <- driver %>%
    transmute(docid,
              input = filepath,
              pages = map2(doc_pg_from, doc_pg_to, seq),
              output = file.path(pdfdir, paste0(docid, ".pdf"))) %>%
    mutate(done = pmap_chr(select(., input, pages, output), make_pdf))

out <- subsetted %>%
    verify(output == done) %>%
    transmute(docid,
              page_count = map_int(pages, length),
              pdfname = done)

outname <- file.path(args$outputdir, "pdf-index.parquet")
write_parquet(out, outname)

# done.
