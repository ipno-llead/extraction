# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

# frontmatter{{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    stringr,
    tidyr,
    yaml
)

parser <- ArgumentParser()
parser$add_argument("--input", default="../import/output/minutes.parquet")
parser$add_argument("--regexes", default="hand/regexes.yaml")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

minutes <- read_parquet(args$input)
regexes <- read_yaml(args$regexes)

# split pages, one row per line{{{
minlines <- minutes %>%
    mutate(text = str_replace_all(text, "(\\n\\s*){3,}", "\\n\\n")) %>%
    mutate(text=str_split(text, "\n")) %>%
    unnest(text) %>%
    mutate(text = str_trim(str_squish(text))) %>%
    filter(text != "") %>%
    group_by(fileid, pageno) %>%
    mutate(lineno = seq_along(text)) %>% ungroup
# }}}

# features{{{
hdr_pagenos <- minlines %>%
    filter(lineno <= 3) %>%
    filter(str_detect(tolower(str_squish(text)), "page [2-9]")) %>%
    distinct(fileid, pageno, re_contpage=TRUE)


hdr_feats <- minlines %>%
    filter(lineno <= 3) %>%
    mutate(map_dfc(regexes, ~str_detect(text, .))) %>%
    pivot_longer(cols=starts_with("re_"),
                 names_to="matchname",
                 values_to="value") %>%
    group_by(f_region, fileid, pageno, matchname) %>%
    summarise(value = any(value), .groups="drop")
# }}}

all_feats <- hdr_feats %>%
    mutate(re_region = str_match(matchname, "^re_(.+)_[^_]+_[0-9]+$")[,2]) %>%
    transmute(fileid, pageno, matchname,
              outvalue = case_when(
                  re_region == f_region ~ value,
                  re_region == "all"    ~ value,
                  TRUE                  ~ FALSE)) %>%
    mutate(outvalue=as.integer(outvalue)) %>%
    pivot_wider(names_from=matchname, values_from=outvalue) %>%
    left_join(hdr_pagenos, by=c("fileid", "pageno"))

out <- minutes %>%
    select(fileid, starts_with("f_"), pageno, label, labeled) %>%
    inner_join(all_feats, by=c("fileid", "pageno"))

stopifnot(nrow(out) == nrow(minutes))

write_parquet(out, args$output)

# done.
