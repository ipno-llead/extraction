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
parser$add_argument("--input", default = "../dl-dropbox/output/la-disc/index.csv")
parser$add_argument("--pdfpath", default = "../dl-dropbox")
args <- parser$parse_args()
# }}}

ind <- read_delim(args$input, delim = "|",
                  col_types = cols(.default = col_character()))

txt <- ind %>%
    select(fileid, filename = local_name) %>%
    mutate(filename = file.path(args$pdfpath, filename)) %>%
    mutate(text = map(filename, pdf_text)) %>%
    unnest(text) %>%
    mutate(text = str_split(text, "\n")) %>%
    unnest(text) %>% mutate(text = str_trim(text)) %>%
    filter(text != "")

nms <- txt %>%
    filter(str_detect(text, "^IN RE\\:")) %>%
    mutate(name = str_replace(text, "IN RE\\:", "") %>% str_trim) %>%
    transmute(fileid,
              filename = str_replace(basename(filename), "\\.pdf", ""),
              extracted_name = name) %>%
    distinct

ids <- txt %>%
    group_by(fileid) %>%
    summarise(text = paste(text, collapse = " ") %>% str_squish,
              .groups = "drop") %>%
    filter(str_detect(text, "Bar Roll Number")) %>%
    mutate(extracted_bar_nbr = str_match(text, "Bar Roll Number ([0-9]{5})")[,2])

nms %>% full_join(ids, by = "fileid") %>%
    distinct(fileid, filename, extracted_name, extracted_bar_nbr)
