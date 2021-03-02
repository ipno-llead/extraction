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
parser$add_argument("--index", default="output/index.csv")
parser$add_argument("--txtdir", default="output/txt300")
parser$add_argument("--DPI", type="integer", default=300)
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# setup etc. {{{
index <- read_delim(args$index, delim="|", na="", col_types='cc')

# input_files <- str_split(args$inputs, "\\|")[[1]] %>%
#     purrr::keep(~str_length(.) > 0)

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

process_pdf <- function(doc, expected_hash,
                        txtdir=args$txtdir, DPI=OCR_DPI) {
    n_pages <- pdf_length(doc)
    hash <- digest::digest(doc, file=TRUE, algo="sha1")
    stopifnot("file has expected hash" = hash == expected_hash)
    fileid <- stub(hash)
    filedir <- paste0(txtdir, "/", hash)
    if (!dir.exists(filedir)) dir.create(filedir, recursive=TRUE)
    eng <- tesseract(language = "eng",
                     options  = list(tessedit_pageseg_mode = 3),
                     cache    = TRUE)
    out <- tibble(filename=doc, fileid=fileid, pageno = seq_len(n_pages)) %>%
        mutate(text=map2_chr(filename, pageno, ocr_cached,
                             engine=eng, DPI=DPI, txtdir=filedir))
}
# }}}

log_info("starting import (using cached xml if available)")
processed <- map2_dfr(index$filename, index$filesha1, process_pdf,
                      txtdir=args$txtdir, DPI=OCR_DPI)
log_info("finished importing documents")

write_parquet(processed, args$output)

# done.
