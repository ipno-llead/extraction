# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--ml_lab", default = "../classify/output/line-labels.parquet")
parser$add_argument("--hr_lab", default = "../classify/output/heuristic-labels.parquet")
parser$add_argument("--minutes", default = "../import/output/minutes.parquet")
args <- parser$parse_args()
# }}}

ml <- read_parquet(args$ml_lab)
hr <- read_parquet(args$hr_lab)
mins <- read_parquet(args$minutes)

mins %>%
    inner_join(ml, by = c("docid", "docpg", "lineno")) %>%
    filter(doctype == "hearing") %>%
    group_by(docid) %>%
    mutate(overall = sum(label %in% c("hearing", "hearing_header")/n())) %>%
    ungroup %>%
    arrange(overall, docid, docpg, lineno) %>%
    select(f_region, docid, docpg, lineno, text, label, overall) %>%
    print(n=25)


hr %>%
    #     filter(label %in% c("hearing_header", "hearing")) %>%
    inner_join(ml, by = c("docid", "docpg", "lineno")) %>%
    mutate(issue = label.x %in% c("hearing", "hearing_header") &
            !label.y %in% c("hearing", "hearing_header")) %>%
    group_by(docid) %>%
    summarise(bloop = sum(issue) / n()) %>%
    arrange(desc(bloop)) %>%
    inner_join(mins, by = "docid") %>%
    inner_join(ml, by = c("docid", "docpg", "lineno")) %>%
    select(docid, docpg, lineno, text, label, marginal) %>% print(n = 50)

    left_join(ml, by = c("docid", "docpg", "lineno"))

    filter(label.x != label.y) %>%
    count(label.x, label.y)
