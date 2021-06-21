# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# frontmatter {{{
pacman::p_load(
    argparse,
    arrow,
    crfsuite,
    dplyr,
    logger,
    purrr,
    rsample,
    tidyr
)

parser <- ArgumentParser()
parser$add_argument("--input", default = "../features/export/output/training-data-features.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# functions {{{
confusion_matrix <- function(predictions, truth, lab_xref) {
    perf <- expand.grid(predicted = lab_xref,
                        truth = lab_xref) %>%
        as_tibble %>%
        left_join(tibble(predicted = predictions$label,
                         marginal  = predictions$marginal,
                         truth     = truth),
                  by=c("predicted", "truth")) %>%
        filter(!is.na(marginal) | truth == predicted) %>%
        group_by(truth, predicted)  %>%
        summarise(n = sum(!is.na(marginal)), .groups="drop") %>%
        pivot_wider(names_from=truth, values_from=n, values_fill=0L) %>%
        arrange(predicted)
    mat <- as.matrix(select(perf, -predicted))
    rownames(mat) <- perf$predicted
    stopifnot(
        "true positives must be on diagonal" = all(rownames(mat) == colnames(mat))
    )
    mat
}

fit_crf <- function(training_data, ...) {
    crf(x = training_data %>% select(-docid, -lineno, -docpg, -label),
        y = training_data$label,
        group = training_data$docid, ...)
}

crf_metrics <- function(train, test, ...) {
    log_info("loo iteration...")
    train <- train %>% tidyr::unnest(data)
    test  <- test  %>% tidyr::unnest(data)
    modfit <- fit_crf(training_data=train,
                      file=tempfile(fileext=".crfsuite"), ...)
    preds <- predict(modfit, newdata=test, group=test$docid)
    # rows are predictions, columns are truth
    confusion <- confusion_matrix(preds, test$label, lab_xref=distinct_labels)
    tibble(
        section = rownames(confusion),
        tru_pos = diag(confusion),
        prd_pos = rowSums(confusion),
        act_pos = colSums(confusion)
    )
}
# }}}

# read data {{{
docs <- read_parquet(args$input)
# should read this from somewhere else:
distinct_labels <- unique(docs$label)
log_info("training data has ", nrow(docs), " rows",
         " (", length(unique(docs$docid)), " documents)")
log_info(length(distinct_labels), " different section labels")
# }}}

# prep features {{{
log_info("prepping data for CRF training")

real2bin <- function(topic) {
    if_else(topic <= -.5,
            -1L,
            if_else(topic >= .5, 1L, 0L))
}

prepped <- docs %>%
    arrange(docid, docpg, lineno) %>%
    select(docid, docpg, lineno,
           #            f_region,
           starts_with("topic_"),
           starts_with("feat_"),
           starts_with("re_"),
           #            starts_with("t_"), starts_with("feat_"),
           label) %>%
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
    mutate_at(vars(-docid, -docpg, -lineno, -label), as.character) %>%
    pivot_longer(cols = c(-docid, -docpg, -lineno, -label),
                 names_to = "variable", values_to = "value") %>%
    filter(!is.na(value)) %>%
    mutate(value = paste0(variable, "=", value)) %>%
    pivot_wider(names_from = variable, values_from = value) %>%
    mutate(across(c(starts_with("topic_"), starts_with("re_"),
                    starts_with("t_")),
                  ~paste(feat_caps, ., sep="|"),
                  .names = "conj_{col}_caps")) %>%
    arrange(docid, docpg, lineno)

log_info("prepped data has ", ncol(prepped), " columns")
# }}}

# loo metrics {{{
log_info("calculating loo models...")
cv <- nest(prepped, data = -docid) %>%
    loo_cv %>%
    mutate(train=map(splits, training),
           test=map(splits, testing))
cv <- cv %>% mutate(metrics = map2(train, test, crf_metrics))

log_info("average (+std. dev) performance on held-out documents")
unnest(cv, metrics) %>%
    mutate(precision=tru_pos/prd_pos, recall=tru_pos/act_pos,
           f1 = 2*precision*recall / (precision+recall)) %>%
    group_by(section) %>%
    summarise(across(c(act_pos, precision, recall, f1),
                     list(mean=mean, sd=sd), na.rm=TRUE,
                     .names="{fn}._.{col}"),
              n_lines=sum(act_pos),
              .groups="drop") %>%
    pivot_longer(c(-section, -n_lines),
                 names_to="col", values_to="val") %>%
    separate(col, into=c("smry", "stat"), sep="\\._\\.") %>%
    mutate(val=signif(val, 2)) %>%
    pivot_wider(names_from=smry, values_from=val) %>%
    transmute(section, n_lines,
              stat, summary=paste0(mean, " (", sd, ")")) %>%
    pivot_wider(names_from=stat, values_from=summary) %>%
    arrange(desc(n_lines)) %>% select(-n_lines) %>%
    rename(n_lines=act_pos, line_type=section) %>% print(n = Inf)

# }}}

model <- fit_crf(prepped, file=args$output)

# done.
