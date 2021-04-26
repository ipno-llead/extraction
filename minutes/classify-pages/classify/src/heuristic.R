# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================
# extraction/individual/minutes/classify-frontpages/classify/src/heuristic.R

pacman::p_load(
    argparse,
    arrow,
    dplyr,
    stringr,
    tidyr
)


parser <- ArgumentParser()
parser$add_argument("--input", default = "../features/output/features.parquet")
parser$add_argument("--output")
args <- parser$parse_args()

feats <- read_parquet(args$input)
labs <- feats %>% filter(labeled) %>% select(fileid, pageno, label)

# should be flagging agendas and exhibits/attachments here
heur <- feats %>%
    select(fileid, pageno, starts_with("re_")) %>%
    pivot_longer(cols=starts_with("re_")) %>%
    filter(value > 0) %>%
    group_by(fileid, pageno) %>%
    summarise(pagetype = case_when(
                any(name == "re_contpage") ~ "continue",
                any(str_detect(name, "_hrg_")) ~ "hearing",
                any(str_detect(name, "_mtg_")) ~ "mtg",
                TRUE ~ "continue"), .groups="drop")

out <- feats %>%
    distinct(fileid, pageno) %>%
    left_join(heur, by=c("fileid", "pageno")) %>%
    replace_na(list(pagetype="continue"))

out %>%
    inner_join(labs, by=c("fileid", "pageno")) %>%
    count(pagetype, label) %>% print

write_parquet(out, args$output)

# done.
