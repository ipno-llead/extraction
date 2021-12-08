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
    mutate(text = str_split(text, "\n")) %>%
    unnest(text) %>%
    filter(str_trim(text) != "") %>%
    group_by(fileid, pageno) %>%
    mutate(lineno = seq_along(text)) %>%
    ungroup
# }}}

# features{{{
pagenos <- minlines %>%
    group_by(fileid, pageno) %>%
    mutate(text = str_squish(text) %>% str_to_lower,
           hd = lineno <= 3, ft = lineno == max(lineno)) %>%
    filter(hd | ft) %>%
    mutate(
        re_frontpage_1 = str_detect(text, "page 1$"),
        re_frontpage_2 = ft & str_detect(text, "^1$"),
        re_contpage_1 = str_detect(text, "page ([2-9])|(1[0-9])"),
        re_contpage_2 = ft & str_detect(text, "^([2-9])|(1[0-9])$"),
    ) %>%
    summarise(across(starts_with("re_"), max), .groups = "drop")

hdr_feats <- minlines %>%
    filter(lineno <= 8) %>%
    mutate(map_dfc(regexes, ~str_detect(str_trim(str_squish(text)), .))) %>%
    pivot_longer(cols = starts_with("re_"),
                 names_to = "matchname",
                 values_to = "value") %>%
    group_by(f_region, fileid, pageno, matchname) %>%
    summarise(value = any(value), .groups = "drop")

all_marg_feats <- hdr_feats %>%
    mutate(re_region = str_match(matchname, "^re_(.+)_[^_]+_[0-9]+$")[, 2]) %>%
    transmute(fileid, pageno, matchname,
              outvalue = case_when(
                  re_region == f_region ~ value,
                  re_region == "all"    ~ value,
                  TRUE                  ~ FALSE)) %>%
    mutate(outvalue = as.integer(outvalue)) %>%
    pivot_wider(names_from = matchname, values_from = outvalue) %>%
    left_join(pagenos, by = c("fileid", "pageno"))

oth_feats <- minlines %>%
    group_by(fileid, pageno) %>%
    mutate(re_slidell_agd_0 = f_region == "slidell" &
               str_detect(str_squish(text), "^MEETING AGENDA$"),
           re_slidell_mtg_9 = f_region == "slidell" &
               str_detect(str_squish(text), "^Board Members (Present)|(Absent)"),
           re_kenner_hrg_1 = f_region == "kenner" & lineno < 6 &
               str_detect(text, "^HEARING OF APPEAL$") &
               str_detect(lag(text), "^CIVIL SERVICE BOARD"),
           re_kenner_agd_0 = f_region == "kenner" &
               str_detect(text, "^AGENDA$") &
               str_detect(lag(text), "^REGULAR MEETING")) %>%
    summarise(across(starts_with("re_"), max), .groups="drop")

# }}}

out <- minutes %>%
    select(fileid, starts_with("f_"), pageno, label, labeled) %>%
    inner_join(all_marg_feats, by=c("fileid", "pageno")) %>%
    inner_join(oth_feats, by=c("fileid", "pageno"))

stopifnot(nrow(out) == nrow(minutes))

write_parquet(out, args$output)

# done.
