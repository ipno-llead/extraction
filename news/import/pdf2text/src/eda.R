# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# testing to figure if/when I can just take embedded text/fonts rather than
# OCR. the problem is it's hard to tell when you haven't got usable text, or
# you've only got a portion of the text, etc.

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    pdftools,
    purrr,
    readr,
    stringr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../index/output/metadata.csv")
args <- parser$parse_args()
# }}}

ind <- read_delim(args$input, delim = "|",
                  col_types = cols(.default = col_character()))

txt <- ind %>%
    select(fileid, filename) %>%
    mutate(filename = str_replace(filename, "extraction/", "")) %>%
    mutate(filename = here::here(filename)) %>%
    mutate(text = map(filename, pdf_text))

txt %>%
    sample_n(1) %>% pluck("text", 1) %>% cat("\n")
