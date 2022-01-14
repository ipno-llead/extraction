# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--scores", default = "output/predictions-all-sents.parquet")
parser$add_argument("--olabs", default = "../import/output/phase2.parquet")
args <- parser$parse_args()
# }}}

# inputs {{{
scores <- read_parquet(args$scores)
labs <- read_parquet(args$olabs)
# }}}

threshold <- .5

# example (human labeled), robert moates
labs %>% filter(docid == "f12d21b9", hrgno == 1) %>%
    filter(label == "initial_charges") %>%
    select(docid, hrgno, snippet) %>% pluck("snippet")

# example machine-labeled, perry bennet
scores %>%
    filter(docid == "75feab01") %>%
    filter(score > threshold) %>% pluck("sentence", 1)



# ignore{{{


docs <- read_parquet("../../extract/export/output/hearings.parquet") %>%
    filter(!is.na(hrg_acc_uid))

docs %>%
    filter(str_detect(hrg_text, regex("sex", ignore_case=T))) %>%
    distinct(docid, hrgno, hrg_accused) %>%
    inner_join(scores, by = c("docid", "hrgno")) %>%
    filter(score >= threshold) %>% pluck("sentence")

scores %>%
    filter(docid == "f12d21b9", hrgno == 1) %>%
    filter(score > threshold) %>%
    select(docid, hrgno, snippet=sentence) %>%
    pluck("snippet")



# candidates
# c0323314 hrgno=1: joshua wilkerson neglect of duty
# 1f6e9bcf hrgno 1

labs %>% filter(docid == "1f6e9bcf")

labs %>%
    filter(docid == "5e8c7896") %>%
    select(docid, hrgno, text = snippet)

scores %>%
    #     filter(docid == "5e8c7896", hrgno == 2) %>%
    select(docid, hrgno, text = sentence, score) %>%
    filter(score > threshold) %>%
    filter(str_detect(text, regex("neglect", ignore_case=T))) %>%
    pluck("text")
           #            label == "initial_charges",
           #            !str_detect(text, "By written"),
           #            !str_detect(text, "Specifically")) %>%
    sample_n(15)




scores %>% filter(docid == "1309351c", hrgno == 1)

scores %>%
    mutate(score_grp = cut(score, c(0, .3, .5, .7, 1))) %>%
    #     mutate(score = 10 * round(score * 10)) %>%
    group_by(score_grp, label) %>%
    summarise(n = n(), score = mean(score)) %>%
    mutate(pct = n/sum(n)) %>% ungroup

scores %>%
    mutate(bloop = score > .3) %>%
    group_by(bloop) %>% summarise(m = mean(label == "initial_charges"))

filter(scores, score > .5) %>% filter(label == "other") %>% pluck("sentence")

filter(scores, score < .3) %>% filter(label == "initial_charges") %>%
    arrange(score)

sc

scores %>%
    filter(score > .5) %>%
    arrange(docid, hrgno, sentence_id) %>%
    filter(!str_detect(sentence, "By written communication")) %>%
    group_by(docid, hrgno) %>%
    summarise(initial_charges = paste(sentence, collapse = " "), .groups = "drop") %>%
    mutate(initial_charges = str_squish(initial_charges)) %>%
    sample_n(1) %>% pluck("initial_charges")

# }}}
