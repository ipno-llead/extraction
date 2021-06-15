# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    crfsuite,
    dplyr,
    logger,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--data", default = "../features/output/minutes-features.parquet")
parser$add_argument("--model", default = "../train/output/line-classifier.crfsuite")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

docs <- read_parquet(args$data)
model <- as.crf(args$model)

# prep features {{{
log_info("prepping data for classification")

real2bin <- function(topic) {
    if_else(topic <= -.5,
            -1L,
            if_else(topic >= .5, 1L, 0L))
}


prepped <- docs %>%
    arrange(docid, docpg, lineno) %>%
    select(docid, docpg, lineno,
           #f_region,
           starts_with("topic_"),
           starts_with("feat_"),
           starts_with("re_"),
           #starts_with("re_"), starts_with("t_"), starts_with("feat_")
           ) %>%
    #     mutate(across(starts_with("t_"), real2bin)) %>%
    group_by(docid) %>%
    mutate(across(c(starts_with("re_"), starts_with("feat_"), starts_with("topic_")),
                  list(nxt1 = ~lead(., 1) %>% replace_na(0L),
                       prv1 = ~lag(., 1) %>% replace_na(0L)),
                  .names = "{fn}_{col}")) %>%
    ungroup %>%
    mutate_at(vars(-docid, -docpg, -lineno), as.character) %>%
    pivot_longer(cols = c(-docid, -docpg, -lineno),
                 names_to = "variable", values_to = "value") %>%
    filter(!is.na(value)) %>%
    mutate(value = paste0(variable, "=", value)) %>%
    pivot_wider(names_from = variable, values_from = value) %>%
    arrange(docid, docpg, lineno)
# }}}

preds <- predict(model, newdata = prepped, group = prepped$docid)

out <- prepped %>%
    select(docid, docpg, lineno) %>%
    bind_cols(preds)

write_parquet(out, args$output)

# done.
