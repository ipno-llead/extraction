# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# NOTES:
#    - vivian: no hearings identified
#    - orleans: no hearings identified
#    - harahan: less structured, will require more thought to parse
#    - addis: fileid 3dcf07f mentions suspension of
#             "a police officer" decided in executive session

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
dt_pattern <- paste0("^(", paste0("(", month.name, ")", collapse="|"), ")",
                     " [0-9]{1,2}, [0-9]{4}")

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

doclines <- read_parquet(args$input)

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
        docpg == 1 & str_detect(chunk_title, "ROLL CALL") ~ "other",
        docpg == 1 & chunkno <= 4 ~ "meeting_header",
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
        docpg == 1 & lineno <=25 & str_detect(text, dt_pattern) ~ "meeting_header",
        hearing & chunk_title == text ~ "hearing_header",
        hearing ~ "hearing",
        TRUE ~ "other")) %>%
    distinct(fileid, pageno, docid, docpg, lineno, linetype)

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
    replace_na(list(linetype = "meeting_header")) %>%
    distinct(fileid, pageno, docid, docpg, lineno, linetype)

knr_mtgs <- doclines %>%
    filter(f_region == "kenner", doctype == "meeting") %>%
    chunk(pattern = "^AGENDA ITEM")

knr_hrg_headers <- knr_mtgs %>%
    arrange(docid, docpg, lineno) %>%
    filter(chunkno >= 1) %>%
    mutate(sec_brk = !allcaps(text)) %>%
    group_by(docid, chunkno) %>%
    mutate(index = cumsum(sec_brk)) %>%
    ungroup %>%
    filter(index == 0)

knr_hrg_head_lines <- knr_hrg_headers %>%
    distinct(docid, docpg, lineno, header=TRUE)

knr_hrg_flg <- knr_hrg_headers %>%
    distinct(docid, chunkno, lineno, text, header = TRUE) %>%
    group_by(docid, chunkno) %>%
    filter(any(str_detect(text, "APPEAL"))) %>%
    ungroup %>%
    distinct(docid, chunkno, hearing=T)

knr <- knr_mtgs %>%
    left_join(knr_hrg_flg, by = c("docid", "chunkno")) %>%
    left_join(knr_hrg_head_lines, by = c("docid", "docpg", "lineno")) %>%
    replace_na(list(hearing = FALSE, header = FALSE)) %>%
    mutate(linetype = case_when(
        hearing & header ~ "hearing_header",
        hearing & str_detect(text, "^Appellant (is)|(was) employed by") ~ "hearing_header",
        hearing ~ "hearing",
        docpg == 1 & chunkno == 0 ~ "meeting_header",
        TRUE ~ "other")) %>%
    distinct(fileid, pageno, docid, docpg, lineno, linetype)

# }}}

# orleans {{{
# doclines %>%
#     filter(f_region == "orleans") %>%
#     chunk(pattern = "^Item #")
# }}}

# lake charles {{{
lc_chunks <- doclines %>%
    filter(f_region == "lake_charles") %>%
    chunk(pattern = "(^[^A-Za-z]{2,})|(on the agenda)")

lc_flag <- lc_chunks %>%
    group_by(fileid, pageno, chunkno) %>%
    summarise(text = paste(text, collapse = " "),
              min_line = min(lineno),
              .groups = "drop") %>%
    filter(str_detect(text, "public hearing"),
           str_detect(text, "Lake Charles Police Department")) %>%
    transmute(fileid, pageno, chunkno, min_line, hearing = TRUE)

lc <- lc_chunks %>%
    left_join(lc_flag, by = c("fileid", "pageno", "chunkno")) %>%
    mutate(linetype = case_when(
            hearing && lineno == min_line ~ "hearing_header",
            hearing ~ "hearing",
            chunkno == 0 & lineno < 10 ~ "meeting_header",
            TRUE ~ "other")) %>%
    distinct(fileid, pageno, docid, docpg, lineno, linetype)
# }}}

# bossier {{{
bossier_chunks <- doclines %>%
    filter(f_region == "bossier") %>%
    chunk(pattern = "^([IVX]+\\.)|^([0-9]+\\.)")

bossier_flag <- bossier_chunks %>%
    group_by(fileid, chunkno) %>%
    summarise(text = paste(text, collapse = " ") %>% str_squish,
              .groups = "drop") %>%
    filter(str_detect(text, regex("appeal hearing", ignore_case = T))) %>%
    transmute(fileid, chunkno, hearing = T)

bsr <- bossier_chunks %>%
    left_join(bossier_flag, by = c("fileid", "chunkno")) %>%
    mutate(csb = str_detect(text, "^CIVIL SERVICE BOARD"),
           dt = str_detect(text, regex(dt_pattern, ignore_case = T))) %>%
    mutate(linetype = case_when(
        docpg == 1 & (csb | dt) ~ "meeting_header",
        hearing & text == chunk_title ~ "hearing_header",
        hearing ~ "hearing",
        TRUE ~ "other")) %>%
    distinct(fileid, pageno, docid, docpg, lineno, linetype)
# }}}

# note: seems like sulphur keeps disciplinary appeal hearings in separate docs
# sulphur {{{
slph <- doclines %>%
    filter(f_region == "sulphur") %>%
    chunk(pattern = regex("^appeal hearing$", ignore_case = TRUE)) %>%
    mutate(hearing = str_detect(chunk_title, regex("^appeal hearing$"))) %>%
    group_by(docid) %>%
    mutate(linetype = case_when(
        docpg == 1 & lineno < 10 ~ "meeting_header",
        hearing & text == chunk_title ~ "hearing_header",
        hearing ~ "hearing",
        TRUE ~ "other")) %>%
    distinct(fileid, pageno, docid, docpg, lineno, linetype)
# }}}

# harahan ??? {{{
# doclines %>%
#     filter(f_region == "harahan") %>%
#     filter(str_detect(text, regex("giglio", ignore_case = T))) %>%
#     pluck("text")
#     sample_n(15) %>% select(text)
# }}}

# youngsville {{{
yvl_chunks <- doclines %>%
    filter(f_region == "youngsville") %>%
    chunk(pattern = regex("^AGENDA ITEM", ignore_case = TRUE))

yvl <- yvl_chunks %>%
    mutate(hearing = str_detect(chunk_title, regex("appeal hearing"))) %>%
    mutate(linetype = case_when(
        chunkno == 0 ~ "meeting_header",
        hearing & chunk_title == text ~ "hearing_header",
        hearing ~ "hearing",
        TRUE ~ "other")) %>%
    distinct(fileid, pageno, docid, docpg, lineno, linetype)

# }}}

# carencro {{{
crn <- doclines %>%
    filter(f_region == "carencro") %>%
    chunk(pattern = "^[a-z0-9]\\.") %>%
    mutate(hearing = str_detect(chunk_title, regex("appeal", ignore_case = T))) %>%
    mutate(linetype = case_when(
        docpg == 1 & lineno <= 5 ~ "meeting_header",
        hearing & chunk_title == text ~ "hearing_header",
        hearing ~ "hearing",
        TRUE ~ "other")) %>%
    distinct(fileid, pageno, docid, docpg, lineno, linetype)
# }}}

# broussard {{{
brs <- doclines %>%
    filter(f_region == "broussard") %>%
    mutate(hrg_start = str_detect(text, regex("appeal hearing", ignore_case = T))) %>%
    arrange(docid, docpg, lineno) %>%
    group_by(docid) %>%
    mutate(hearing = cummax(hrg_start)) %>%
    ungroup %>%
    mutate(linetype = case_when(
        docpg == 1 & lineno <= 7 ~ "meeting_header",
        hrg_start ~ "hearing_header",
        hearing > 0 ~ "hearing",
        TRUE ~ "other")) %>%
    distinct(fileid, pageno, docid, docpg, lineno, linetype)
# }}}

# shreveport {{{
dtct <- function(string, pattern) str_detect(string, regex(pattern, ignore_case=T))
shreve <- doclines %>% filter(f_region == "shreveport") %>%
    arrange(docid, docpg, lineno) %>%
    mutate(re_dkt = dtct(text, "docket"),
           re_apl = dtct(text, "appeal from"),
           re_suscom = dtct(text, "sustained complaint"),
           re_police = dtct(text, "police"),
           re_motion = str_detect(text, "^Motion"),
           re_board = str_detect(text, "^Board voted")) %>%
    group_by(docid, docpg) %>%
    mutate(hrg_start =
            (re_dkt | re_apl | re_suscom) & (re_police | lead(re_police)),
           hrg_end = re_motion | lag(re_board)
        ) %>%
    mutate(linetype = case_when(
        dtct(text, "ruling chart") ~ "other",
        docpg == 1 & dtct(text, "roll call") ~ "other",
        docpg == 1 & lineno <= 4 ~ "meeting_header",
        dtct(text, "\\(appeals") ~ "other",
        hrg_start ~ "hearing_header",
        hrg_end ~ "hearing",
        lag(hrg_start, default = FALSE) ~ "hearing",
        lag(hrg_end, default = FALSE) ~ "other",
        TRUE ~ NA_character_)) %>%
    fill(linetype, .direction = "down") %>%
    ungroup %>%
    replace_na(list(linetype = "other")) %>%
    distinct(fileid, pageno, docid, docpg, lineno, linetype)
# }}}

classes <- bind_rows(ww, ebr, la, mv, sl, knr_hearing,
                     knr, lc, bsr, slph, yvl, crn, brs, shreve) %>%
    select(fileid, pageno, docid, docpg, lineno, linetype) %>%
    arrange(docid, docpg, lineno) %>%
    group_by(docid, docpg) %>%
    mutate(tofill = lead(linetype) == "hearing_header" &
           lag(linetype) == "hearing_header" &
           linetype != "hearing_header") %>% ungroup %>%
    replace_na(list(tofill = FALSE)) %>%
    mutate(linetype = if_else(tofill, "hearing_header", linetype)) %>%
    select(-tofill)


out <- doclines %>%
    inner_join(classes, by = c("docid", "docpg", "lineno")) %>%
    transmute(docid, docpg, lineno,
              label = linetype,
              label_source = "heuristic")

write_parquet(out, args$output)

# done.
