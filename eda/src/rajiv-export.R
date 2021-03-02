# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

pacman::p_load(
    argparse,
    dplyr,
    jsonlite,
    purrr,
    readr,
    stringr
)


parser <- ArgumentParser()
parser$add_argument("--index", default = "../individual/minutes/ocr/output/index.csv")
parser$add_argument("--ocrdir", default = "../individual/minutes/ocr/output/txt300")
parser$add_argument("--output", default = "output/ocrd-minutes.json")
args <- parser$parse_args()

index <- read_delim(args$index, delim="|", na="", col_types='cccccc')

txt <- tibble(txtfile=list.files(args$ocrdir, recursive=TRUE, pattern="*.txt",
                          full.names=TRUE)) %>%
    mutate(filesplit=str_split(txtfile, "/"),
           filepieces=map_int(filesplit, length)) %>%
    mutate(filesha1=map2_chr(filesplit, filepieces, ~.x[.y-1]),
           pageno=map2_chr(filesplit, filepieces, ~.x[.y])) %>%
    distinct(filesha1, pageno, txtfile) %>%
    mutate(ocr_txt=map(txtfile, read_lines)) %>%
    mutate(ocr_txt=map_chr(ocr_txt, paste, collapse="\n"))

txt <- txt %>%
    arrange(filesha1, pageno) %>%
    group_by(filesha1) %>%
    summarise(page_count = n_distinct(pageno),
              text_content = paste(ocr_txt, collapse="\n\n"),
              .groups="drop")

index %>%
    left_join(txt,by="filesha1") %>%
    transmute(title=basename(filename), url,
              db_path, db_id, db_content_hash, sha1_hash=filesha1,
              page_count, text_content) %>%
    write_json(args$output, pretty=TRUE)

# done.
