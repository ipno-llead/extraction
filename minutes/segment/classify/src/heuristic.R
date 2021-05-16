# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    stringr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../import/output/minutes.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# helpers{{{
allcaps <- function(string) {
    str_detect(string, "[A-Z]") & !str_detect(string, "[a-z]")
}

chunk <- function(lns, pattern) {
    chunks <- lns %>%
        arrange(fileid, pageno, lineno) %>%
        mutate(newchunk = str_detect(text, pattern)) %>%
        group_by(docid) %>%
        mutate(chunkno = cumsum(newchunk)) %>%
        ungroup
    chunk_titles <- chunks %>%
        filter(newchunk) %>%
        distinct(docid, chunkno, chunk_title = text)
    chunks %>%
        select(-newchunk) %>%
        left_join(chunk_titles, by = c("docid", "chunkno")) %>%
        arrange(fileid, pageno, chunkno, lineno)
}
# }}}

docs <- read_parquet(args$input)

doclines <- docs %>%
    arrange(fileid, pageno) %>%
    group_by(docid) %>% mutate(docpg = seq_along(text)) %>%
    mutate(text = str_split(text, "\n"),
           lineno = map(text, ~seq_along(.))) %>%
    unnest(c(text, lineno)) %>%
    mutate(text = str_squish(text)) %>% filter(text != "") %>% ungroup

# westwego hearings{{{
ww <- doclines %>%
    filter(doctype == "hearing", f_region == "westwego") %>%
    arrange(docid, docpg, lineno) %>%
    group_by(docid, docpg) %>%
    mutate(linetype = case_when(
        docpg == 1 & lineno == min(lineno) ~ "meeting_header",
        docpg == 1 & lag(lineno) == min(lineno) ~ "hearing_header",
        docpg == 1 & str_detect(lag(text), regex("appellant (is)|(was) employed")) ~ "hearing",
        TRUE        ~ NA_character_)) %>%
    group_by(docid) %>% fill(linetype, .direction = "down") %>% ungroup %>%
    select(fileid, pageno, docid, docpg, lineno, linetype)

# }}}

# east baton rouge {{{


ebr_chunks <- doclines %>%
    filter(doctype == "meeting", f_region == "east_baton_rouge") %>%
    chunk(pattern =  "^([0-9]\\.? )?[A-Z ]{8,}")

ebr_hrg_flg <- ebr_chunks %>%
    filter(str_detect(chunk_title, "APPEAL HEARING")) %>%
    distinct(docid, chunkno, hearing=TRUE)

ebr <- ebr_chunks %>%
    left_join(ebr_hrg_flg, by = c("docid", "chunkno")) %>%
    mutate(linetype = case_when(
        hearing & chunk_title == text ~ "hearing_header",
        hearing ~ "hearing",
        docpg == 1 & chunkno <= 4 ~ "meeting_header",
        docpg == 1 & str_detect(chunk_title, "ROLL CALL") ~ "other",
        docpg == 1 & chunkno < 10 &
            str_detect(text, "^BATON ROUGE") ~ "meeting_header",
        docpg == 1 & chunkno < 10 &
            str_detect(text, "COUNCIL CHAMBERS") ~ "meeting_header",
        docpg == 1 & lineno < 10 &
            str_detect(lead(text), "^BATON ROUGE") ~ "meeting_header",
        TRUE ~ "other")) %>%
    distinct(fileid, pageno, docid, docpg, lineno, linetype)
# }}}

# la-state{{{

la_chunks <- doclines %>%
    filter(f_region == "louisiana_state") %>%
    chunk(pattern = "^([0-9]\\.)")

la_hrg_flg <- la_chunks %>%
    distinct(docid, chunkno, chunk_title) %>%
    filter(!is.na(chunk_title)) %>%
    filter(str_detect(chunk_title, regex("(appeal)|(in the matter of)|(hearing)",
                                  ignore_case=TRUE)),
           !str_detect(chunk_title, "[Pp]roposed"),
           !str_detect(chunk_title, "[Cc]hanges")) %>%
    distinct(docid, chunkno, hearing=TRUE)

la <- la_chunks %>%
    left_join(la_hrg_flg, by = c("docid", "chunkno")) %>%
    arrange(docid, docpg, lineno) %>%
    mutate(linetype = case_when(
            chunkno == 0 & allcaps(str_sub(text, 1, 6)) ~ "meeting_header",
            hearing & text == chunk_title ~ "hearing_header",
            hearing ~ "hearing",
            TRUE ~ "other")) %>%
    select(fileid, pageno, docid, docpg, lineno, linetype)
# }}}

# mandeville{{{
mv_chunks <- doclines %>%
    filter(f_region == "mandeville") %>%
    chunk(pattern = "(^Agenda Item)|([Aa]genda [Ii]tem\\:)|(item on the agenda)")

mv_hrg_flg <- mv_chunks %>%
    filter(str_detect(chunk_title, regex("appeal", ignore_case=TRUE))) %>%
    distinct(docid, chunkno, hearing = TRUE)

mv <- mv_chunks %>%
    left_join(mv_hrg_flg, by = c("docid", "chunkno")) %>%
    mutate(linetype = case_when(
            hearing & chunk_title == text ~ "hearing_header",
            hearing ~ "hearing",
            chunkno == 0 & docpg == 1 ~ "meeting_header",
            TRUE ~ "other")) %>%
    select(fileid, pageno, docid, docpg, lineno, linetype)

# }}}

# vivian{{{
# doclines %>%
#     filter(f_region == "vivian") %>%
#     chunk(pattern = "^[A-Z 0-9\\.]{4,}")
# }}}

# slidell{{{
sl_chunks <- doclines %>%
    filter(f_region == "slidell", doctype == "meeting") %>%
    chunk(pattern =  "(^[()0-9]+[().])|(^[a-z](\\.|\\)))")

sl_hrg_flg <- sl_chunks %>%
    filter(str_detect(chunk_title, regex("appeal", ignore_case = TRUE))) %>%
    distinct(docid, chunkno, hearing = TRUE)

sl <- sl_chunks %>%
    left_join(sl_hrg_flg, by = c("docid", "chunkno")) %>%
    replace_na(list(hearing = FALSE)) %>%
    mutate(linetype = case_when(
        hearing && chunk_title == text ~ "hearing_header",
        hearing ~ "hearing",
        TRUE ~ "other")) %>%
    distinct(fileid, pageno, docid, docpg, linetype)

# }}}

# kenner {{{

# hearings
knr_hearing <- doclines %>%
    filter(f_region == "kenner", doctype == "hearing") %>%
    arrange(docid, docpg, lineno) %>%
    group_by(docid, docpg) %>%
    mutate(linetype = case_when(
        str_detect(text, "HEARING OF APPEAL") ~ "hearing_header",
        str_detect(lag(text), "^Appellant (is)|(was) employed by") ~ "hearing",
        TRUE ~ NA_character_)) %>%
    group_by(docid) %>% fill(linetype, .direction = "down") %>% ungroup %>%
    replace_na(list(linetype = "page_header")) %>%
    distinct(fileid, pageno, docid, docpg, lineno, linetype)

knr_mtgs <- doclines %>%
    filter(f_region == "kenner", doctype == "meeting") %>%
    chunk(pattern = "^AGENDA ITEM")

knr_hrg_flg <- knr_mtgs %>%
    filter(!str_detect(text, "[a-z]")) %>%
    group_by(docid, chunkno) %>%
    filter(any(str_detect(text, "APPEAL"))) %>%
    ungroup %>%
    distinct(docid, chunkno, hearing=T)

knr <- knr_mtgs %>%
    left_join(knr_hrg_flg, by = c("docid", "chunkno")) %>%
    replace_na(list(hearing = FALSE)) %>%
    mutate(linetype = case_when(
        hearing & allcaps(text) ~ "hearing_header",
        hearing & str_detect(text, "^Appellant (is)|(was) employed by") ~ "hearing_header",
        hearing ~ "hearing",
        docpg == 1 & chunkno == 0 ~ "meeting_header",
        TRUE ~ "other")) %>%
    distinct(fileid, pageno, docid, docpg, lineno, linetype)

# }}}

classes <- bind_rows(ww, ebr, la, mv, sl, knr_hearing, knr) %>%
    select(docid, docpg, lineno, linetype) %>%
    arrange(docid, docpg, lineno) %>%
    group_by(docid, docpg) %>%
    mutate(tofill = lead(linetype) == "hearing_header" &
           lag(linetype) == "hearing_header" &
           linetype != "hearing_header") %>% ungroup %>%
    replace_na(list(tofill = FALSE)) %>%
    mutate(linetype = if_else(tofill, "hearing_header", linetype)) %>%
    select(-tofill)


out <- doclines %>%
    inner_join(classes, by = c("docid", "docpg", "lineno"))

write_parquet(out, args$output)

# done.