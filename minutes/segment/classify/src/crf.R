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
parser$add_argument("--data")
parser$add_argument("--model")
parser$add_argument("--truth")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

docs <- read_parquet(args$data)
model <- as.crf(args$model)
truth <- read_parquet(args$truth) %>% distinct(fileid, pageno, lineno, label)

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
           starts_with("topic_"),
           starts_with("feat_"),
           starts_with("re_")) %>%
    mutate(across(starts_with("t_"), real2bin)) %>%
    group_by(docid) %>%
    mutate(across(c(starts_with("re_"), starts_with("feat_"),
                    starts_with("topic_"), starts_with("t_")),
                  list(nxt1 = ~lead(., 1) %>% replace_na(0L),
                       prv1 = ~lag(., 1) %>% replace_na(0L),
                       nxt2 = ~lead(., 2) %>% replace_na(0L),
                       prv2 = ~lag(., 2) %>% replace_na(0L)),
                  .names = "{fn}_{col}")) %>%
    ungroup %>%
    mutate_at(vars(-docid, -docpg, -lineno), as.character) %>%
    pivot_longer(cols = c(-docid, -docpg, -lineno),
                 names_to = "variable", values_to = "value") %>%
    filter(!is.na(value)) %>%
    mutate(value = paste0(variable, "=", value)) %>%
    pivot_wider(names_from = variable, values_from = value) %>%
    mutate(across(c(starts_with("topic_"), starts_with("re_"),
                    starts_with("t_")),
                  ~paste(feat_caps, ., sep="|"),
                  .names = "conj_{col}_caps")) %>%
    arrange(docid, docpg, lineno)
# }}}

preds <- predict(model, newdata = prepped, group = prepped$docid)

label_fixes <- docs %>%
    distinct(fileid, pageno, docid, docpg, lineno) %>%
    inner_join(truth, by = c("fileid", "pageno", "lineno")) %>%
    select(docid, docpg, lineno, truth = label)

out <- prepped %>%
    select(docid, docpg, lineno) %>%
    bind_cols(preds) %>%
    left_join(label_fixes, by = c("docid", "docpg", "lineno")) %>%
    mutate(marginal     = if_else(is.na(truth), marginal, NA_real_),
           label        = coalesce(truth, label),
           label_source = if_else(is.na(truth), "model", "human")) %>%
    select(-truth)

log_info("count of labels by jurisdiction and document type")
out %>%
    inner_join(docs %>% distinct(docid, f_region, doctype),
               by = "docid") %>%
    count(f_region, doctype, label) %>%
    pivot_wider(names_from = label, values_from = n, values_fill = 0)

log_info("avg. marginal probability of labels, by jursidiction and doctype")
out %>%
    inner_join(docs %>% distinct(docid, f_region, doctype),
               by = "docid") %>%
    group_by(f_region, doctype, label) %>%
    summarise(marginal = mean(marginal), .groups = "drop") %>%
    pivot_wider(names_from = label, values_from = marginal)

write_parquet(out, args$output)

# done.
