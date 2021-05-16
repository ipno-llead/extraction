# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# front matter {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    stringr,
    tidyr
)

parser <- ArgumentParser()
parser$add_argument("--input")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# helpers {{{

simplify_text <- function(strings) {
    str_to_lower(strings) %>%
        str_replace_all("[^a-z0-9 ]", "") %>%
        str_squish
}

re_month <- c(month.name, month.abb) %>%
    str_to_lower %>%
    paste0("(", ., ")", collapse="|")

re_date <- paste0("(", re_month, ")", " [0-9]{1,2} [0-9]{4}" )

# }}}

docs <- read_parquet(args$input)

# try scraping {{{
scraped_dates <- docs %>%
    filter(linetype == "meeting_header") %>%
    group_by(docid) %>%
    summarise(text=paste(text, collapse = " ")) %>%
    mutate(text = simplify_text(text)) %>%
    mutate(date = str_extract(text, re_date),
           date = lubridate::mdy(date)) %>%
    filter(!is.na(date)) %>%
    transmute(docid, s_date = date,
              s_year = lubridate::year(date) %>% as.integer,
              s_month = lubridate::month(date) %>% as.integer,
              s_day = lubridate::day(date) %>% as.integer,
              scraped = TRUE)
# }}}

# output scraped date if possible, fall back to date from filename {{{
out <- docs %>%
    distinct(docid, jurisdiction = f_region, f_year, f_month, f_day) %>%
    left_join(scraped_dates, by = "docid") %>%
    replace_na(list(scraped = FALSE)) %>%
    mutate(mtg_year  = if_else(scraped, s_year, f_year),
           mtg_month = if_else(scraped, s_month, f_month),
           mtg_day   = if_else(scraped, s_day, f_day),
           mtg_dt_source = case_when(
                scraped ~ "scraped",
                !is.na(f_year) ~ "filename",
                TRUE ~ NA_character_)) %>%
    select(docid, mtg_year, mtg_month, mtg_day, mtg_dt_source)
# }}}

write_parquet(out, args$output)

# done.
