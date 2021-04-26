# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================
# extraction/minutes/import/index/src/meta.R

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

# args{{{
parser <- ArgumentParser()
parser$add_argument("--input")
parser$add_argument("--dbpath")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# functions{{{
# name relative to repository root
# makes it easier to use from anywhere with e.g. here::here()
repo_name <- function(filename, dbpath=args$dbpath) {
    paste0(dbpath, str_extract(filename, "/output/.*$"))
}

dtct <- function(string, term) str_detect(string, regex(term, ignore_case=TRUE))

dateparse <- function(fn) {
    stopifnot(length(fn) == length(unique(fn)))
    monthstrings <- str_to_lower(c(month.name, month.abb))
    monthmap <- set_names(rep(1:12, 2), monthstrings)
    re_month <- paste0("(", monthstrings, ")", collapse="|")
    patterns <- list(
        mdy_num  = "[0-9]{1,2} [0-9]{1,2} [0-9]{2,4}",
        mdy_string = paste0("(",re_month, ")", " [0-9]{1,2} [0-9]{2,4}")
    )
    cln <- str_to_lower(fn) %>% str_replace_all("[^a-z0-9 ]", " ") %>% str_squish
    out <- tibble(orig=fn, cln=cln) %>%
        mutate(map_dfc(patterns, ~str_extract(cln, .))) %>%
        select(-cln) %>%
        pivot_longer(cols=c(-orig),
                     names_to="matchtype",
                     values_to="match") %>%
        filter(!is.na(match)) %>%
        separate(match, into = c("month", "day", "year"), sep=" ") %>%
        mutate(century = if_else(as.integer(year) < 30, "20", "19")) %>%
        mutate(month = case_when(
                matchtype == "mdy_string" ~ monthmap[month],
                matchtype == "mdy_num" ~ as.integer(month),
                TRUE ~ NA_integer_),
               day = as.integer(day),
               year = case_when(
                str_length(year) == 4 ~ as.integer(year),
                str_length(year) == 2 ~ as.integer(paste0(century, year)),
                TRUE ~ NA_integer_)) %>%
        select(orig, month, day, year)
    out %>% group_by(orig) %>% filter(n() == 1) %>% ungroup
}

# }}}

ind <- read_parquet(args$input) %>% select(-url) # until we get this working

dates <- dateparse(ind$filename)

out <- ind %>%
    mutate(npages   = map_int(filename, pdf_length),
           region   = str_split(filename, "/") %>% map_chr(4),
           filepath = repo_name(filename),
           fileid   = str_sub(filesha1, 1, 7)) %>%
    mutate(fn = basename(filename)) %>%
    mutate(file_category = case_when(
            dtct(fn, "minutes")           ~ "minutes",
            dtct(fn, "meeting min")       ~ "minutes",
            dtct(fn, "cs board mtg")      ~ "minutes",
            dtct(fn, "fpcsb_mprr")        ~ "minutes",
            dtct(fn, "mpecsbm")           ~ "minutes",
            dtct(fn, "transcript")        ~ "transcript",
            dtct(fn, "v\\.? city of")     ~ "transcript",
            dtct(fn, "city of [^\\s]+ v") ~ "transcript",
            dtct(fn, "agenda")            ~ "agenda",
            dtct(fn, "memo")              ~ "memo",
            TRUE ~ "other")) %>%
    left_join(dates, by = c(filename="orig")) %>%
    select(fileid, region, year, month, day,
           file_category, npages, filepath, filesha1,
           starts_with("db_"))

stopifnot(
    "nrows changed"  = nrow(out) == nrow(ind),
    "duplicate fileids" = length(unique(out$fileid)) == nrow(out)
)

write_delim(out, args$output, delim="|", na="")

# done.
