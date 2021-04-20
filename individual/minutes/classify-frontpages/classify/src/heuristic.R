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
parser$add_argument("--minutes", default = "../import/output/minutes.parquet")
parser$add_argument("--labels", default = "../import/output/labeled-data.parquet")
args <- parser$parse_args()

mins <- read_parquet(args$minutes) %>%
    mutate(region = str_match(filename, "output/([^/]+)/")[,2])
labs <- read_parquet(args$labels)

ind_minutes <- regex("(minutes)|(meeting min)|(fpcsb_mprr)", ignore_case=TRUE)

mins %>%
    distinct(region, filename=basename(filename)) %>%
    filter(!str_detect(filename, ind_minutes)) %>%
    filter(!str_detect(region, "kenner"))




minlines <- mins %>%
    mutate(text = str_replace_all(text, "(\\n\\s*){2,}", "\\n")) %>%
    mutate(text=str_split(text, "\n")) %>%
    unnest(text) %>%
    mutate(text = str_trim(str_squish(text))) %>%
    filter(text != "") %>%
    group_by(region, fileid, pageno) %>%
    mutate(lineno = seq_along(text)) %>% ungroup %>%
    select(-filename)

minlines %>%
    filter(lineno <= 3) %>%
    count(region, text, sort=T) %>%
    filter(region != "kenner")

re_hdrs <- c("MINUTES", "MUNICIPAL", "POLICE",
             "CIVIL SERVICE BOARD", "CITY COUNCIL",
             "Civil Service Board", "LOUISIANA STATE POLICE COMMISSION",
             "COUNCIL CHAMBERS") %>% paste0("(", ., ")", collapse="|")


tops <- minlines %>%
    filter(lineno <= 5) %>%
    filter(str_detect(text, "[A-Za-z]+ [0-9]{1,2}, [12][09][0-9]{2}") |
           str_detect(text, re_hdrs)) %>%
    distinct(fileid, pageno)

labs %>%
    filter(label > 0) %>%
    anti_join(tops, by=c("fileid", pg="pageno")) %>%
    inner_join(minlines, by=c("fileid", pg="pageno")) %>%
    filter(lineno <= 5) %>% 
    count(text, sort=T)
    print(n=Inf)

mins %>%
    left_join(mutate(tops, newpage=T),
              by=c("fileid", "pageno")) %>%
    replace_na(list(newpage=F)) %>%
    arrange(fileid, pageno) %>%
    mutate(docid = cumsum(newpage)) %>%
    group_by(region, docid, filename) %>%
    summarise(p0=min(pageno), pn=max(pageno),
              npages=n_distinct(pageno), .groups='drop') %>%
    filter(npages > 15) %>%
    transmute(region, fn=basename(filename), p0, pn) %>%
    print(n=Inf)
    filter()
    group_by(region) %>% summarise(median_pages=median(npages), hi_pages = quantile(npages, .9))
    distinct(region, docid) %>% count(region)
