# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================
# extraction/individual/minutes/classify-frontpages/classify/src/heuristic.R

# load libs{{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    stringr,
    tidyr
)
# }}}

# command line args{{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../features/output/features.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

feats <- read_parquet(args$input)
labs <- feats %>% filter(labeled) %>% select(fileid, pageno, label)

# should be flagging agendas and exhibits/attachments here
heur <- feats %>%
    select(fileid, pageno, starts_with("re_")) %>%
    pivot_longer(cols=starts_with("re_")) %>%
    filter(value > 0) %>%
    group_by(fileid, pageno) %>%
    summarise(pagetype = case_when(
                any(str_detect(name, "_agd_")) ~ "agenda",
                #                 any(name == "re_contpage") ~ "continuation",
                any(str_detect(name, "_hrg_")) ~ "hearing",
                any(str_detect(name, "_mtg_")) ~ "meeting",
                TRUE ~ "continuation"), .groups="drop")

out <- feats %>%
    distinct(fileid, pageno) %>%
    left_join(heur, by=c("fileid", "pageno")) %>%
    replace_na(list(pagetype="continuation"))

out %>%
    inner_join(labs, by=c("fileid", "pageno")) %>%
    count(pagetype, label) %>% print

write_parquet(out, args$output)

# done.
