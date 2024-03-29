# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    digest,
    dplyr,
    here,
    logger,
    magick,
    pdftools,
    purrr,
    readr,
    stringr,
    tesseract,
    tidyr,
    tools,
    xml2
)
# }}}

# command line args {{{
parser <- ArgumentParser()
parser$add_argument("--index")
parser$add_argument("--txtdir", default="output/txt300")
parser$add_argument("--DPI", type="integer", default=300)
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# setup etc. {{{
index <- read_delim(args$index, delim="|", na="",
                    col_types=cols(
                        .default = col_character(),
                        year     = col_integer(),
                        month    = col_integer(),
                        day      = col_integer()))

OCR_DPI <- args$DPI
log_info("DPI: ", OCR_DPI)
stub <- function(hash) str_sub(hash, 1, 7)
# }}}

# ocr code {{{
ocr_cached <- function(filename, pageno, engine, DPI, txtdir) {
    txt_fn <- sprintf("%04i", pageno)
    txt_fn <- paste0(txtdir, "/", txt_fn, ".txt")
    if (file.exists(txt_fn)) return(readLines(txt_fn) %>% paste(collapse="\n"))
    log_info("OCR for: ", txt_fn)
    img <- pdf_render_page(filename, page = pageno,
                           dpi = DPI, numeric = FALSE) %>%
        image_read
    txt <- ocr(img, engine=engine, HOCR=FALSE)
    writeLines(txt, txt_fn)
    txt
}

process_pdf <- function(doc, expected_hash, npages,
                        txtdir=args$txtdir, DPI=OCR_DPI) {
    hash <- digest::digest(doc, file=TRUE, algo="sha1")
    stopifnot("file has expected hash" = hash == expected_hash)
    filedir <- paste0(txtdir, "/", hash)
    if (!dir.exists(filedir)) dir.create(filedir, recursive=TRUE)
    eng <- tesseract(language = "eng",
                     options  = list(tessedit_pageseg_mode = 1),
                     cache    = TRUE)
    map2_chr(doc, seq_len(npages), ocr_cached,
             engine=eng, DPI=DPI, txtdir=filedir)
}
# }}}

log_info("starting import (using cached xml if available)")

processed <-  index %>%
    filter(filetype == "pdf") %>%
    transmute(doc=here::here(str_replace(filepath, "^[^\\/]+/", "")),
              expected_hash = filesha1,
              npages = map_int(doc, pdf_length),
              txtdir=args$txtdir, DPI=OCR_DPI) %>%
    mutate(text = pmap(., process_pdf)) %>%
    transmute(filesha1=expected_hash,
              pageno=map(text, seq_along),
              text=text) %>%
    unnest(c(pageno, text))
log_info("finished importing documents")

out <- index %>%
    inner_join(processed, by="filesha1") %>%
    select(fileid, pageno, text)

write_parquet(out, args$output)

# done.
