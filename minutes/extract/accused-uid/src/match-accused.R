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
    dplyr,
    logger,
    lubridate,
    stringdist,
    stringr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--xtract")
parser$add_argument("--dates")
parser$add_argument("--classes")
parser$add_argument("--roster")
parser$add_argument("--docxref")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

xtract  <- read_parquet(args$xtract)
roster  <- read_parquet(args$roster)
dates   <- read_parquet(args$dates)
classes <- read_parquet(args$classes)
mtg_jur <- read_parquet(args$docxref) %>%
    distinct(docid, jurisdiction, agency, agency_slug)

# tokenize names to aid matching {{{
extracted_tokens <- xtract %>%
    inner_join(mtg_jur, by = "docid") %>%
    left_join(dates, by = "docid") %>%
    mutate(mtg_date = make_date(mtg_year, mtg_month, mtg_day)) %>%
    mutate(hrg_accused = str_to_lower(hrg_accused),
           tok_acc = str_split(hrg_accused, boundary("word"))) %>%
    select(docid, jurisdiction, agency_slug, agency,
           hrgno, mtg_date, hrg_accused, tok_acc) %>%
    unnest(tok_acc)

roster_tokens <- roster %>%
    mutate(ros_name = str_c(replace_na(first_name,  ""),
                        replace_na(middle_name, ""),
                        replace_na(last_name,   ""),
                        sep = " "),
           ros_name = str_squish(str_to_lower(ros_name))) %>%
    select(-middle_initial, -middle_name) %>%
    pivot_longer(cols = c(last_name, first_name),
                 names_to = "token_type", values_to = "token") %>%
    filter(!is.na(token)) %>%
    mutate(token = str_to_lower(token)) %>%
    rename(ros_agency = agency)
# }}}

log_info("starting with ", nrow(xtract), " distinct hearings")

# compare <- function(mtg, ros) {
#     jur <- stringdist(mtg$jurisdiction, ros$agency,
#                       method="jaccard", q = 4) < .5
#     chron <- between(mtg$mtg_date, ros$start, ros$end)
# }

matcher <- extracted_tokens %>%
    inner_join(roster_tokens, by = c("tok_acc" = "token")) %>%
    mutate(namedist = stringdist(hrg_accused, ros_name,
                                 method="jaccard", q=4),
           jurdist = stringdist(tolower(agency_slug),
                                tolower(str_replace_all(ros_agency, "\\s+", "-")),
                                method="jaccard", q=4),
           dt_in_range = mtg_date >= start & mtg_date <= end)

pass1 <- matcher %>%
    filter(namedist <= .5, jurdist <= .5, dt_in_range) %>%
    distinct(docid, hrgno, uid) %>%
    group_by(docid, hrgno) %>%
    filter(n_distinct(uid) == 1) %>%
    ungroup

log_info(nrow(pass1), " roster matches based on name + jurisdiction + date")

pass2 <- matcher %>%
    anti_join(pass1, by = c("docid", "hrgno")) %>%
    filter(namedist <= .5, jurdist <= .5, is.na(mtg_date)) %>%
    group_by(docid, hrgno) %>% filter(n_distinct(uid) == 1) %>% ungroup %>%
    distinct(docid, hrgno, uid)

log_info(nrow(pass2), " matches based on name + jurisdiction (and NA date)")

pass3 <- matcher %>%
    anti_join(pass1, by = c("docid", "hrgno")) %>%
    anti_join(pass2, by = c("docid", "hrgno")) %>%
    filter(jurdist <= .5, dt_in_range, str_detect(hrg_accused, ros_name)) %>%
    group_by(docid, hrgno) %>% filter(n_distinct(uid) == 1) %>% ungroup %>%
    distinct(docid, hrgno, uid)

log_info(nrow(pass3), " matches based on jur+date + name contained")

pass4 <- matcher %>%
    anti_join(pass1, by = c("docid", "hrgno")) %>%
    anti_join(pass2, by = c("docid", "hrgno")) %>%
    anti_join(pass3, by = c("docid", "hrgno")) %>%
    filter(jurdist <= .5, namedist <= .5) %>%
    group_by(docid, hrgno) %>% filter(namedist == min(namedist)) %>%
    group_by(docid, hrgno) %>% filter(n_distinct(uid) == 1) %>% ungroup %>%
    distinct(docid, hrgno, uid)

log_info(nrow(pass4), " matches based on name+jur")

pass5 <- matcher %>%
    anti_join(pass1, by = c("docid", "hrgno")) %>%
    anti_join(pass2, by = c("docid", "hrgno")) %>%
    anti_join(pass3, by = c("docid", "hrgno")) %>%
    anti_join(pass4, by = c("docid", "hrgno")) %>%
    filter(jurdist <= .5, dt_in_range) %>%
    filter(str_detect(hrg_accused, "police")) %>%
    group_by(docid, hrgno) %>% filter(namedist == min(namedist)) %>%
    filter(n_distinct(uid) == 1) %>%
    ungroup %>% distinct(docid, hrgno, uid)

log_info(nrow(pass5),
         " matches based on date + jur, selecting most similar name,",
         " only when 'police' is in person's title")

pass6 <- matcher %>%
    anti_join(pass1, by = c("docid", "hrgno")) %>%
    anti_join(pass2, by = c("docid", "hrgno")) %>%
    anti_join(pass3, by = c("docid", "hrgno")) %>%
    anti_join(pass4, by = c("docid", "hrgno")) %>%
    anti_join(pass5, by = c("docid", "hrgno")) %>%
    inner_join(classes, by = c("docid", "hrgno")) %>%
    filter(!str_detect(hrg_accused, "fire")) %>%
    #     filter(hrg_type %in% c("police", "unknown")) %>%
    group_by(docid, hrgno, uid) %>%
    filter(n_distinct(tok_acc) > 1 | namedist < .5) %>%
    group_by(docid, hrgno) %>%
    filter(namedist == min(namedist)) %>%
    filter(n_distinct(uid) == 1) %>%
    ungroup %>%
    distinct(docid, hrgno, uid)

log_info(nrow(pass6), " matches from final pass")

out <- xtract %>%
    left_join(bind_rows(pass1, pass2, pass3, pass4, pass5, pass6),
              by = c("docid", "hrgno")) %>%
    verify(nrow(.) == nrow(xtract)) %>%
    rename(hrg_acc_uid = uid)

write_parquet(out, args$output)

# done.
