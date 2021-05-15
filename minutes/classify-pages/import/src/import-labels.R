# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================
# extraction/individual/minutes/classify-pages/import/src/import-labels.R

pacman::p_load(
    argparse,
    arrow,
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
    mutate(label=clean_label(label)) %>%
    mutate(label = case_when(
                notes == "drop" ~ "other",
                notes == "agenda" ~ "agenda",
                label > 0 ~ "front",
                label == 0 ~ "continuation",
                TRUE ~ "other"))

labs %>%
    select(fileid, pg, label) %>%
    write_parquet(args$output)

# done.
