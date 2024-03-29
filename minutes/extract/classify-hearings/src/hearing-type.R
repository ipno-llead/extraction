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

hearings <- read_parquet(args$input) %>%
    filter(linetype %in% c("hearing_header", "hearing"),
           !is.na(hrgno))

log_info(nrow(distinct(hearings, docid, hrgno)), " distinct hearings to start")

# classify{{{
out <- hearings %>%
    arrange(docid, docpg, lineno) %>%
    group_by(docid, hrgno) %>%
    slice_head(n = 7) %>%
    summarise(text = paste(text, collapse = " ") %>% str_squish,
              .groups = "drop") %>%
    #     pluck("text") %>% dtct("employed by (.+) fire department")
    mutate(fire =
            dtct(text, "firefighter") |
            dtct(text,"fire captain") |
            dtct(text,"fire chief") |
            dtct(text,"fire communications officer") |
            dtct(text,"fire driver") |
            dtct(text, "\\(fire department\\)") |
            dtct(text, "Fire") |
            dtct(text, "employed by (.+) fire department"),
        police =
            dtct(text, "police officer") |
            #             dtct(text, "officer") |
            dtct(text, "public safety") |
            str_detect(text, "Police") |
            str_detect(text, "Corrections") |
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
