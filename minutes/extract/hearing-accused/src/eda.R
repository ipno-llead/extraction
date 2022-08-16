library(arrow); library(tidyverse)
mins <- read_parquet("../import/output/minutes.parquet")
cur <- read_parquet("output/hrg-accused.parquet")
lab <- read_parquet("../../extract-snippets/import/output/all-labels.parquet") %>%
    filter(label == "accused_officer_name")

xref <- read_parquet("../import/output/minutes.parquet") %>%
    distinct(fileid, docid, hrgno, docpg, text) %>%
    group_by(fileid, docid, hrgno) %>%
    summarise(text = paste0(text, collapse = " "),
              doc_start = min(docpg),
              doc_end = max(docpg),
              .groups = "drop")

lab %>%

lab %>%
    filter(!is.na(hrgloc)) %>%
    anti_join(cur, by = c("docid")) %>%
    #     select(docid, hrgno, snippet) %>%
    inner_join(mins, by = c("docid")) %>%
    filter(docid == "0a45da75") %>%
    select(snippet, hrgno.x) %>%
    print(n=Inf)
    inner_join(mins, by = c("docid", "hrgno")) %>%
    select(docid, hrgno, snippet, text) %>% 
    select(text, snippet)
    print(n=Inf)

cur %>% filter(docid =="0a45da75")

# cur %>% inner_join(xref, by = c("docid", "hrgno")) %>%
#     left_join(lab, by = "fileid") %>%
#     select(doc_start, doc_end, doc_pg_from, text.x, text.y) %>% print(n=25)
#     filter(doc_start <= doc_pg_from, doc_end >= doc_pg_to) %>%
#     select(text.x, text.y)
