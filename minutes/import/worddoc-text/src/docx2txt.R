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
    assertr,
    digest,
    dplyr,
    here,
    purrr,
    readr,
    stringr,
    textreadr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

meta <- read_delim(args$input, delim = "|",
                   col_types = cols(.default = col_character()))

docxs <- meta %>% filter(filetype == "word") %>%
    select(fileid, filepath, filesha1) %>%
    transmute(fileid,
              filename=here::here(str_replace(filepath, "^[^\\/]+/", "")),
              expected_hash = filesha1,
              actual_hash = map_chr(filename, digest,
                                    file=TRUE, algo="sha1")) %>%
    verify(expected_hash == actual_hash) %>%
    mutate(w_version = str_extract(filename, "docx?$")) %>%
    verify(w_version %in% c("docx", "doc")) %>%
    mutate(reader = paste0("read_", w_version))

scraped <- docxs %>%
    mutate(filename = map(filename, list)) %>%
    mutate(text = map2(reader, filename, do.call))

out <- scraped %>% transmute(fileid, pageno = 1L, text) %>%
    unnest(text) %>%
    group_by(fileid, pageno) %>%
    summarise(text = paste(text, collapse = "\n"), .groups="drop")

write_parquet(out, args$output)
