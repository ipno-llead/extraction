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
parser$add_argument("--inputs")
parser$add_argument("--xmldir", default="output/xml300")
parser$add_argument("--DPI", type="integer", default=300)
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

input_files <- str_split(args$inputs, "\\|")[[1]] %>%
    purrr::keep(~str_length(.) > 0)

# metadata etc. {{{
OCR_DPI <- args$DPI
log_info("DPI: ", OCR_DPI)
stub <- function(hash) str_sub(hash, 1, 7)

meta <- function(fn) {
    file_sha1 <- digest::digest(fn, algo="sha1", file=TRUE)
    log_info(basename(fn), " sha1sum: ", file_sha1)
    info <- pdf_info(fn)
    metadata <- as_tibble(pdf_pagesize(fn)) %>%
        # page sizes are reported in points, easier to reason about inches
        mutate_all(~./72) %>%
        mutate(filename  = str_replace(getwd(), here::here(), ""),
               filename  = paste0(filename, "/", fn),
               file_sha1 = file_sha1,
               fileid    = stub(file_sha1),
               pg        = seq_len(nrow(.)),
               creator   = info$keys$Creator,
               producer  = info$keys$Producer,
               title     = info$keys$Title,
               created   = info$created,
               modified  = info$modified,
               layout    = info$layout) %>%
        select(filename, pg, everything())
    log_info(nrow(metadata), " pages")
    metadata
}
# }}}

# helper fns {{{
process_image <- function(img) {
    w <- dim(img[[1]])[2]
    h <- dim(img[[1]])[3]
    geom <- paste0(
        w-200, "x", h-120, "+150+60"
    )
    image_crop(img, geom)
}

ocr_cached <- function(filename, pageno, engine, DPI=OCR_DPI, xmldir) {
    xml_fn <- sprintf("%04i", pageno)
    xml_fn <- paste0(xmldir, "/", xml_fn, ".xml")
    if (file.exists(xml_fn)) return(read_xml(xml_fn))
    log_info("OCR for: ", xml_fn)
    img <- pdf_render_page(filename, page = pageno,
                           dpi = DPI, numeric = FALSE) %>%
        image_read %>% process_image
    hocr <- ocr(img, HOCR=TRUE, engine=engine)
    res <- read_xml(hocr)
    write_xml(res, xml_fn)
    res
}

xtract <- function(pg) {
    words <- xml_find_all(pg, "//span[@class='ocrx_word']")
    lines <- map(words, xml_parent)
    paragraphs <- map(lines, xml_parent)
    blocks <- map(paragraphs, xml_parent)
    tibble(
           #         page_id      = xml_attr(pg, "id"),
        block_id     = map_chr(blocks, xml_attr, "id"),
        paragraph_id = map_chr(paragraphs, xml_attr, "id"),
        line_id      = map_chr(lines, xml_attr, "id"),
        line_size    = map_chr(lines, xml_attr, "title"),
        word_id      = map_chr(words, xml_attr, "id"),
        loc_conf     = map_chr(words, xml_attr, "title"),
        text         = xml_text(words)
    )
}

meta2hash <- function(metadata) {
    hash <- unique(metadata$file_sha1)
    stopifnot(length(hash) == 1)
    hash
}

process_pdf <- function(doc, xmldir) {
    metadata <- meta(doc)
    n_pages <- pdf_length(doc)
    hash <- meta2hash(metadata)
    fileid <- stub(hash)
    xmldir <- paste0(args$xmldir, "/", hash)
    if (!dir.exists(xmldir)) dir.create(xmldir, recursive=TRUE)
    eng <- tesseract(language = "eng",
                     options  = list(tessedit_pageseg_mode = 6),
                     cache    = TRUE)
    ocrd <- map(seq_len(n_pages),
                ~ocr_cached(doc, pageno=., engine=eng, xmldir=xmldir) )
    pages <- map(ocrd, xml_find_all, "/div[@class='ocr_page']")
    flat_pages <- map_dfr(pages, xtract, .id = "pg")
    out <- flat_pages %>%
        mutate(bbox = str_extract(loc_conf, "bbox ([0-9]{1,4}(\\s|;)){4}"),
               bbox = str_replace_all(bbox, "(bbox)|;", "") %>% str_trim,
               conf = str_extract(loc_conf, "[0-9]+$"),
               line_size = str_extract(line_size, "x_size [^;]+;"),
               line_size = str_replace_all(line_size, "(^x_size)|(;)", "") %>%
                   str_trim) %>%
        separate(bbox, into = c("x0", "y0", "x1", "y1"), sep = "\\s+") %>%
        mutate(across(ends_with("_id"), ~str_extract(., "[0-9]+$"))) %>%
        select(-loc_conf) %>%
        mutate_at(vars(-text, -line_size), as.integer) %>%
        mutate(line_size = as.numeric(line_size)) %>%
        mutate(fileid = fileid) %>% select(fileid, everything())
    list(output = out, metadata=metadata)
}
# }}}

log_info("starting import (using cached xml if available)")
processed <- map(input_files, process_pdf)
docs <- map_dfr(processed, "output") %>% mutate(dpi = OCR_DPI)
metadata <- map_dfr(processed, "metadata")
log_info("finished importing documents")

meta_fn <- paste0(args$output, "-index.csv")
write_parquet(docs, args$output)
write_delim(metadata, meta_fn, delim="|", na="")

# done.
