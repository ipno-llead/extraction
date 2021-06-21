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
    assertr,
    dplyr,
    purrr,
    readxl,
    tidyr,
    yaml
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--traindir", default = "input/training-labels")
parser$add_argument("--fixes", default = "hand/label-fixes.yaml")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

recognized_labels <- c(
    "meeting_header",
    "roll_call",
    "hearing_header",
    "hearing",
    "other"
)

required_cols <- c("fileid", "pageno", "lineno", "predicted", "actual")

# import data {{{
read <- function(excelfile, required) {
    lab <- read_excel(excelfile)
    stopifnot(all(required %in% names(lab)))
    select(lab, !!!required)
}

repair <- read_yaml(args$fixes) %>% unlist

labs <- list.files(args$traindir, full.names = TRUE) %>%
    set_names %>%
    map_dfr(read, required = required_cols,
            .id = "trainfile")
# }}}

# label validation/fixing before export {{{
out <- labs %>%
    mutate(actual = if_else(actual %in% recognized_labels,
                            actual, repair[actual])) %>%
    verify(actual %in% recognized_labels)
# }}}

cat("actual (rows) by predicted (columns)", "\n",
    "====================================", "\n", sep="")
count(out, predicted, actual) %>%
    pivot_wider(names_from  = predicted,
                values_from = n,
                values_fill = 0L)

write_parquet(out, args$output)

# done.