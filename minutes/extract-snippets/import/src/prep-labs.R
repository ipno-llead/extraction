# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    corpus,
    dplyr,
    stringr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "output/training/phase2.parquet")
parser$add_argument("--output", default = "output/all-labels.parquet")
args <- parser$parse_args()
# }}}

labs <- read_parquet(args$input) %>% filter(!is.na(text))


texts <- labs %>% distinct(docid, hrgno, text)
sents <- text_split(texts$text, units = "sentences")

splits <- as_tibble(sents[c("parent", "index")]) %>%
    mutate(sent = as.character(sents$text)) %>%
    nest(data = -parent)

sentlocs <- texts %>% mutate(split = splits$data) %>%
    unnest(split) %>%
    rename(sentence_id = index) %>%
    group_by(docid, hrgno) %>%
    mutate(sentend = cumsum(str_length(sent) + 1),
           sentstart = lag(sentend, default = 0) + 1) %>%
    ungroup %>%
    select(docid, hrgno, sentence_id, sentence=sent, sentstart, sentend)

lbl_locs <- labs %>%
    #     filter(label == "initial_charges") %>%
    distinct(docid, hrgno, labstart = start, labend = end, snippet, label) %>%
    filter(str_trim(label) != "")
    ## TODO:
    #filter(label %in% c("initial_discipline", "initial_charges", "appeal_denied", "incident_summary"))

out <- sentlocs %>%
    left_join(lbl_locs, by = c("docid", "hrgno")) %>%
    mutate(label = case_when(
        labstart < sentend & labend > sentstart ~ label,
        str_detect(sentence, regex("department regulation", ignore_case = T)) ~ "initial_charges",
        TRUE ~ "other")) %>%
    mutate(label = if_else(label %in% c("irrelevant_document", "other"), "", label)) %>%
    distinct(docid, hrgno, sentence_id, sentence, label) %>%
    group_by(docid, hrgno, sentence_id, sentence) %>%
    summarise(label = paste(label, collapse = " ") %>% str_trim,
              .groups = "drop") %>%
    mutate(validation = runif(nrow(.)) > .6)

write_parquet(out, args$output)

# labeled_out <- labs %>% filter(label == "initial_charges") %>%
#     arrange(docid, hrgno, start) %>%
#     group_by(docid, hrgno) %>%
#     summarise(start = min(start), end = max(end), .groups = "drop")
# 
# out <- distinct(labs, docid, hrgno, text) %>%
#     left_join(labeled_out, by = c("docid", "hrgno"))
# 
# write_parquet(out, args$output)

# done.



