# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    assertr,
    dplyr,
    lubridate,
    stringr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

docs <- read_parquet(args$input)

# westwego hearings{{{
re_emp <- "^Appellant ((is)|(was)) employed by the Westwego (.+) as a (.+)$"
re_acc <- "^Hearing of Appeal by (.+) on (.+)$"

ww <- docs %>%
    filter(doctype == "hearing", f_region == "westwego") %>%
    mutate(text = str_split(text, "\n")) %>%
    unnest(text) %>% mutate(text = str_squish(text)) %>% filter(text != "") %>%
    mutate(accused = str_match(text, re_acc)[,2],
           date = str_match(text, re_acc)[,3],
           employer = str_match(text, re_emp)[,5],
           title = str_match(text, re_emp)[,6]) %>%
    group_by(docid, fileid, pageno) %>%
    summarise(across(c(accused, date, employer, title), max, na.rm=TRUE),
              .groups="drop") %>%
    filter(str_detect(employer, "[Pp]olice")) %>%
    mutate(date = lubridate::mdy(date)) %>%
    transmute(docid, fileid, pageno,
              year=year(date), month=month(date), day=day(date), accused)

# }}}

# east baton rouge (not exhaustive yet){{{
ebr <- docs %>%
    filter(doctype == "mtg", f_region == "east_baton_rouge") %>%
    mutate(text = str_split(text, "\n")) %>%
    unnest(text) %>% mutate(text = str_squish(text)) %>% filter(text != "") %>%
    mutate(accused = str_match(text, "APPEAL HEARING FOR (.+)$")[,2]) %>%
    filter(!is.na(accused)) %>%
    transmute(docid, fileid, pageno,
              year=as.integer(f_year),
              month=as.integer(f_month),
              day=as.integer(f_day), accused) %>%
    distinct
# }}}

# la-state{{{
lsp <- docs %>%
    filter(f_region == "louisiana_state") %>%
    mutate(text = str_split(text, "\n")) %>%
    unnest(text) %>% mutate(text = str_squish(text)) %>% filter(text != "") %>%
    filter(str_detect(text, "^\\s*[0-9]\\.")) %>%
    filter(str_detect(text, regex("(appeal)|(in the matter of)|(hearing)", ignore_case=TRUE)),
           !str_detect(text, "[Pp]roposed"),
           !str_detect(text, "[Cc]hanges"),) %>%
    mutate(accused = str_match(text, "(([Mm]atter)|([Aa]ppeals?)) of ([A-Z][^\\(,]+)")[,5],
           accused = str_replace_all(accused, "[Aa]ppeal", ""),
           accused = str_trim(accused)) %>%
    transmute(docid, fileid, pageno,
              year=as.integer(f_year),
              month=as.integer(f_month),
              day=as.integer(f_day),
           accused) %>%
    distinct
# }}}

# nothing found in vivian??{{{
docs %>%
    filter(f_region == "vivian") %>%
    mutate(text = str_split(text, "\n")) %>%
    unnest(text) %>% mutate(text = str_squish(text)) %>% filter(text != "") %>%
    filter(str_detect(text, "HEARING")) %>% print(n=Inf)
# }}}

# mandeville{{{
mvl <- docs %>%
    filter(f_region == "mandeville") %>%
    mutate(text = str_split(text, "\n")) %>%
    unnest(text) %>% mutate(text = str_squish(text)) %>% filter(text != "") %>%
    filter(str_detect(text, "^Agenda Item"),
           str_detect(text, regex("appeal", ignore_case=TRUE))) %>%
    mutate(accused = str_match(text, "[Aa]ppeal by ([^,]+),")[,2]) %>%
    transmute(docid, fileid, pageno,
              year=as.integer(f_year),
              month=as.integer(f_month), day=as.integer(f_day),
              accused) %>%
    distinct
# }}}

# slidell{{{
sldl <- docs %>%
    filter(f_region == "slidell") %>%
    mutate(text = str_split(text, "\n")) %>%
    unnest(text) %>% mutate(text = str_squish(text)) %>% filter(text != "") %>%
    group_by(fileid, pageno) %>%
    mutate(accused = if_else(str_detect(lead(text), "^[Vv]ersus"), text, NA_character_)) %>%
    ungroup %>%
    filter(!is.na(accused)) %>%
    transmute(docid, fileid, pageno,
           year = as.integer(f_year),
           month = as.integer(f_month),
           day = as.integer(f_day),
           accused) %>% distinct
# }}}

out <- bind_rows(ww, ebr, lsp, mvl, sldl) %>% distinct %>%
    mutate(accused=str_to_lower(accused))

doc_xref <- docs %>% group_by(docid) %>%
    summarise(doc_pg_from=min(pageno), doc_pg_to=max(pageno), .groups="drop")

roster <- readr::read_csv("input/roster.csv")

roster_tokens <- roster %>% distinct(uid, first_name, last_name) %>%
    pivot_longer(cols=-uid, names_to="name_type", values_to="name") %>%
    mutate(name=str_to_lower(name)) %>% select(-name_type)

roster_xref <- roster %>%
    transmute(uid, name = paste(str_to_lower(first_name),
                                str_to_lower(last_name)))

matched <- out %>%
    distinct(docid, fileid, pageno, accused) %>%
    mutate(acc_token = str_split(accused, "\\s+")) %>%
    unnest(acc_token) %>%
    inner_join(roster_tokens, by=c(acc_token="name")) %>%
    group_by(docid, fileid, pageno, accused, uid) %>%
    filter(n_distinct(acc_token) > 1) %>%
    ungroup %>%
    distinct(docid, fileid, pageno, accused, uid)

db <- readr::read_delim("../import/index/output/metadata.csv", delim="|") %>%
    select(fileid, db_path, filepath)

export <- out %>%
    left_join(matched, by=c("docid", "fileid", "pageno", "accused")) %>%
    inner_join(doc_xref, by="docid") %>%
    left_join(select(roster, uid, first_name, last_name, middle_name),
              by="uid") %>%
    left_join(db, by="fileid") %>%
    transmute(docid, fileid, file_db_path=db_path, doc_pg_from, doc_pg_to,
              doc_match_page = pageno - doc_pg_from + 1,
              file_match_page = pageno,
              year, month, day, accused, matched_uid = uid, first_name, last_name, middle_name)

doctext <- docs %>%
    filter(docid %in% export$docid) %>%
    arrange(fileid, pageno) %>%
    group_by(docid) %>%
    summarise(ocr_text = paste(text, collapse="\n"), .groups="drop") %>%
    mutate(ocr_text = str_replace_all(ocr_text, "(\n[ ]*){3,}", "\n\n"),
           ocr_text = str_trim(ocr_text))

export %>%
    left_join(doctext, by="docid") %>%
    mutate(page_count = doc_pg_to - doc_pg_from + 1) %>%
    readr::write_tsv("output/minutes-accused-20210503.tsv")
#     writexl::write_xlsx("output/minutes-accused-20210503.xlsx")
pacman::p_load(purrr, qpdf)

bloop <- export %>%
    distinct(docid, fileid, from=doc_pg_from, to=doc_pg_to) %>%
    inner_join(db, by="fileid") %>%
    mutate(input=str_replace(filepath, "^[^/]+/", ""),
           input=here::here(input),
           pages=map2(from, to, seq),
           output=paste0("output/pdfs/", docid, ".pdf")) %>%
    select(input, pages, output) %>%
    mutate(done = pmap_chr(., pdf_subset))



# done.
