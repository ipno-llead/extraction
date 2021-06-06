# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    readr,
    stringr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--docs")
parser$add_argument("--outputdir")
args <- parser$parse_args()
# }}}

txtdir <- file.path(args$outputdir, "txt")
if (!dir.exists(txtdir)) dir.create(txtdir, recursive = TRUE)

docs <- read_parquet(args$docs)

doctxt <- docs %>%
    arrange(docid, fileid, pageno) %>%
    group_by(docid) %>%
    summarise(ocr_text = paste(text, collapse="\n"), .groups="drop") %>%
    mutate(ocr_text = str_replace_all(ocr_text, "(\n[ ]*){3,}", "\n\n"),
           ocr_text = str_trim(ocr_text),
           filename = file.path(txtdir, paste0(docid, ".txt")))

walk2(doctxt$ocr_text, doctxt$filename,
      write_lines, sep = "\n", append = FALSE)

outname <- file.path(args$outputdir, "txt-index.parquet")
out <- doctxt %>% distinct(docid, txtname = filename)

write_parquet(out, outname)

# done.
