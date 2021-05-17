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
    dplyr,
    logger,
    stringr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../import/output/minutes.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

dtct <- function(string, pattern) {
    str_detect(string, regex(pattern, ignore_case = TRUE))
}

hearings <- read_parquet(args$input) %>% filter(linetype == "hearing_header")

log_info(nrow(distinct(hearings, docid, hrgno)), " distinct hearings to start")

# classify{{{
out <- hearings %>%
    mutate(fire =
            dtct(text, "firefighter") |
            dtct(text,"fire captain") |
            dtct(text,"fire chief") |
            dtct(text, "\\(fire department\\)"),
            dtct(text, "employed by (.+) fire department"),
        police =
            dtct(text, "police officer") |
            dtct(text, "officer") |
            dtct(text, "employed by (.+) police department")) %>%
    group_by(docid, hrgno) %>%
    summarise(fire = any(fire), police = any(police), .groups="drop") %>%
    mutate(hrg_type = case_when(
        police & !fire ~ "police",
        fire & !police ~ "fire",
        TRUE ~ "unknown")) %>% select(docid, hrgno, hrg_type)
# }}}

log_info("breakdown: ")
out %>% count(hrg_type) %>% print

write_parquet(out, args$output)

# done.
