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
    jsonlite,
    pdftools,
    purrr,
    readr,
    stringr,
    stringdist,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../dl-dropbox/output/la-disc/index.csv")
parser$add_argument("--pdfpath", default = "../dl-dropbox")
args <- parser$parse_args()
# }}}

strdist <- function(string1, string2) {
    stringdist(str_to_lower(string1) %>% str_replace_all("[^a-z ]", ""),
               str_to_lower(string2) %>% str_replace_all("[^a-z ]", ""),
               method = "cosine", q = 3)
}


ind <- read_delim(args$input, delim = "|",
                  col_types = cols(.default = col_character())) %>%
    mutate(filename = str_replace(basename(local_name), "\\.pdf", "")) %>%
    group_by(fileid) %>%
    mutate(duplicate_file = n_distinct(local_name) > 1) %>% ungroup

txt <- ind %>%
    select(fileid, local_name, filename) %>%
    mutate(path = file.path(args$pdfpath, local_name)) %>%
    mutate(text = map(path, pdf_text)) %>%
    mutate(pageno = map(text, seq_along)) %>%
    unnest(c(text, pageno)) %>%
    mutate(text = str_split(text, "\n")) %>%
    mutate(lineno = map(text, seq_along)) %>%
    unnest(c(text, lineno)) %>% mutate(text = str_trim(text)) %>%
    filter(text != "") %>%
    select(fileid, filename, pageno, lineno, text)

nms <- txt %>%
    filter(str_detect(text, "^IN RE\\:")) %>%
    mutate(extracted_name = str_replace(text, "IN RE\\:", "") %>% str_trim) %>%
    filter(!str_detect(extracted_name, "Disciplinary Counsel")) %>%
    transmute(fileid, filename, extracted_name) %>%
    distinct %>%
    mutate(similarity = 1 - strdist(filename, extracted_name)) %>%
    ungroup %>% mutate(matches_filename = similarity > .25) %>%
    select(-filename, -similarity)

ids <- txt %>%
    group_by(fileid) %>%
    summarise(text = paste(text, collapse = " ") %>% str_squish,
              .groups = "drop") %>%
    filter(str_detect(text, "[Bb]ar [Rr]oll [Nn]umber")) %>%
    mutate(extracted_bar_nbr = str_match(text, "[Bb]ar [Rr]oll [Nn]umber (is )?([0-9]{5})")[,3]) %>%
    select(-text)

dockets <- txt %>%
    group_by(fileid) %>%
    summarise(text = paste(text, collapse = " ") %>% str_squish,
              .groups = "drop") %>%
    filter(str_detect(text, "(DOCKET )?(NO\\.)|(NUMBER\\:?)\\s*[0-9\\-A-Z]+")) %>%
    mutate(extracted_dkt_nbr = str_match(text,  "((DOCKET )?(NO\\.)|(NUMBER\\:?))\\s*([0-9\\-A-Z]+)")[,6]) %>%
    select(-text)


out <- ind %>%
    distinct(fileid, filename, dropbox = db_path, duplicate_file) %>%
    left_join(nms, by = "fileid") %>%
    left_join(ids, by = "fileid") %>%
    left_join(dockets, by = "fileid") %>%
    distinct(fileid, filename, dropbox, duplicate_file,
             extracted_name, extracted_bar_nbr, extracted_dkt_nbr) %>%
    group_by(fileid, filename, dropbox) %>%
    summarise(duplicate_file = unique(duplicate_file),
              extracted_name = paste0(unique(extracted_name), collapse = " ||| "),
              extracted_bar_nbr = unique(extracted_bar_nbr),
              extracted_dkt_nbr = unique(extracted_dkt_nbr),
              .groups = "drop")



labs <- c(
    "CONCLUSION",
    "INTRODUCTION",
    "PROCEDURAL HISTORY",
    "DISCUSSION",
    "DECREE",
    #     "RECOMMENDATION",
    #     "RECOMMENDATION TO THE LOUISIANA SUPREME COURT",
    #     "FOR THE ADJUDICATIVE COMMITTEE",
    "FORMAL CHARGES",
    "EVIDENCE",
    "LAW AND FINDINGS OF FACT",
    "BACKGROUND AND PROCEDURAL HISTORY",
    "INTRODUCTION AND PROCEDURAL HISTORY",
    "DISSENT",
    "FOR THE COMMITTEE",
    "ODC EXHIBITS",
    "UNDERLYING FACTS",
    "UNDERLYING FACTS AND PROCEDURAL HISTORY",
    "RULES VIOLATED",
    "APPENDIX")


lablocs <- txt %>%
    mutate(map_dfc(labs, ~str_detect(text, .))) %>%
    mutate(f = str_detect(text, "^[XIV]+\\.")) %>%
    pivot_longer(cols = c(-fileid, -filename, -pageno, -lineno, -text)) %>%
    filter(value) %>%
    transmute(fileid, pageno, lineno, lab = TRUE) %>%
    distinct

chunked <- txt %>%
    left_join(lablocs, by = c("fileid", "pageno", "lineno")) %>%
    replace_na(list(lab = F)) %>%
    group_by(fileid) %>%
    mutate(section_id = cumsum(lab)) %>%
    group_by(fileid, section_id) %>%
    summarise(text = paste(text, collapse = "\n"), .groups = "drop") %>%
    mutate(text = if_else(section_id == 0,
                          text,
                          str_replace_all(text, "\\n", " ") %>% str_squish))

json <- out %>%
    inner_join(chunked, by = "fileid") %>%
    mutate(section_id = sprintf("%s-%03d", fileid, section_id)) %>%
    select(fileid, filename, duplicate_file, section_id,
           dropbox, extracted_name, extracted_bar_nbr,
           extracted_dkt_nbr, text) %>%
    mutate(json = pmap(., list) %>% map_chr(toJSON, auto_unbox = TRUE)) %>%
    arrange(fileid, filename, section_id)

fl <- "output/prosecutors-doccano.jsonl"
if (file.exists(fl)) file.remove(fl)
walk(json$json, cat, "\n", file = fl, append = TRUE)
