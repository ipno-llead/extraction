library(tidyverse)
xref <- read_parquet("../../classify-pages/export/output/minutes.parquet") %>%
    distinct(docid, fileid, pageno) %>%
    group_by(docid, fileid) %>%
    summarize(page_range = str_glue("{min(pageno)}-{max(pageno)}"),
              .groups = "drop")

fileids <- read_delim("../../import/index/output/metadata.csv", delim = "|") %>%
    distinct(fileid, db_path)

doclines %>%
    mutate(xs = str_detect(text, regex("executive session", ignore_case = T))) %>%
    arrange(docid, docpg, lineno) %>%
    group_by(docid) %>%
    filter(xs |
           lag(xs, default = FALSE) |
           lead(xs, default = FALSE) |
           lead(xs, n = 2, default = FALSE)) %>%
    group_by(docid) %>% summarise(text = paste(text, collapse = " ")) %>%
    filter(str_detect(text, regex("(misconduct)|(police)|(trooper)|(officer)|(appeal)|(hearing)", ignore_case=T))) %>%
    inner_join(xref, by = "docid") %>%
    inner_join(fileids, by = "fileid") %>%
    select(docid, fileid, db_path, page_range, surrounding_text = text) %>%
    writexl::write_xlsx("output/executive-session.xlsx")
