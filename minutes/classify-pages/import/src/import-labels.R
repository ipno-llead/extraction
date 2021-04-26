# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================
# extraction/individual/minutes/classify-pages/import/src/import-labels.R

pacman::p_load(
    argparse,
    arrow,
    assertr,
    dplyr,
    logger,
    purrr,
    readxl
)


parser <- ArgumentParser()
parser$add_argument("--inputdir", default="input/labeled-data")
parser$add_argument("--output")
args <- parser$parse_args()

clean_label <- function(label) {
    log_info("unique labels: ", paste(unique(label), collapse=", "))
    log_info("converting all non-NA labels to 1")
    out <- label
    out[!is.na(label)] <- 1L
    out[is.na(label)] <- 0L
    as.integer(out)
}

labs <- list.files(args$inputdir, full.names=TRUE) %>%
    set_names %>%
    map_dfr(read_xlsx, .id="labeler") %>%
    filter(is.na(notes) | ! notes %in% c("drop", "agenda"))

labs %>% mutate(label=clean_label(label)) %>%
    select(fileid, pg, label) %>%
    verify(label %in% c(1L, 0L)) %>%
    write_parquet(args$output)

# done.
