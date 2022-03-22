# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# frontmatter{{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    stringr,
    tidyr,
    tidytext,
    yaml
)

parser <- ArgumentParser()
parser$add_argument("--input", default = "../import/output/minutes.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

minutes <- read_parquet(args$input)
mins <- minutes %>% filter(labeled)

# split pages, one row per line{{{
minlines <- mins %>%
    mutate(text = str_replace_all(text, "(\\n\\s*){3,}", "\\n\\n")) %>%
    mutate(text = str_split(text, "\n")) %>%
    unnest(text) %>%
    filter(str_trim(text) != "") %>%
    group_by(fileid, pageno) %>%
    mutate(lineno = seq_along(text)) %>%
    mutate(caps_pct = str_count(text, "[A-Z]") / str_length(text)) %>%
    ungroup

minlines %>%
    filter(lineno <= 5) %>%
    mutate(token = str_split(text, "\\s+")) %>%
    unnest(token) %>%
    mutate(token = str_squish(token),
           token = str_to_lower(token)) %>%
    anti_join(stop_words, by = c(token = "word")) %>%
    filter(str_count(token, "[A-Za-z]") >= 3) %>%
    mutate(bigram = str_glue("{lag(token)} {token}", .na=NULL)) %>%
    group_by(f_region, label) %>%
    mutate(ndocstotal = n_distinct(fileid)) %>%
    group_by(f_region, label, bigram) %>%
    summarise(ndocs = n_distinct(fileid),
              ndocstotal = unique(ndocstotal),
              .groups = "drop_last") %>%
    mutate(pct = ndocs / ndocstotal) %>%
    slice_max(order_by = pct, n = 5, with_ties = F) %>%
    filter(label == "front") %>%
    print(n=Inf)

tfs <- minlines %>%
    filter(lineno <= 5) %>%
    mutate(token = str_split(text, "\\s+")) %>%
    unnest(token) %>%
    mutate(token = str_squish(token), label) %>%
    filter(str_count(token, "[A-Za-z]") >= 3) %>%
    group_by(f_region, label, token) %>%
    summarise(n = n(), .groups = "drop") %>%
    nest(data = -f_region) %>%
    mutate(data = map(data, bind_tf_idf, token, label, n))

tfs %>%
    unnest(data) %>% group_by(f_region, label) %>%
    slice_max(order_by = tf_idf, n = 3, with_ties = FALSE) %>%
    filter(label == "front") %>%
    group_by(f_region, label) %>%
    distinct(f_region, token)

# }}}

minlines %>% nest(data = c(-f_region, -label))


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

