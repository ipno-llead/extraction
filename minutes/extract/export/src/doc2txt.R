# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================


# front {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    jsonlite,
    purrr,
    readr,
    writexl,
    stringr
)

parser <- ArgumentParser()
parser$add_argument("--input", default = "../merge/output/hearings.parquet")
parser$add_argument("--meta", default = "../import/output/metadata.csv")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# import {{{
db <- read_delim(args$meta, delim='|', na='',
                 col_types = cols(.default = col_character())) %>%
    select(fileid, db_path)

docs <- read_parquet(args$input) %>%
    left_join(db, by = "fileid")
# }}}

# helper {{{
rptout <- function(doc) {
    hrgno <- str_pad(doc$hrgno, 3, pad="0", side="left")
    filename <- paste0("output/docs/", doc$hrg_type, "/", doc$docid, "-", hrgno, ".txt")
    dirnm <- dirname(filename)
    if (!dir.exists(dirnm)) dir.create(dirnm, recursive = TRUE)
    sink(filename)
    on.exit(sink())
    cat("FILE INFO", "\n")
    cat("=========", "\n")
    cat("file id:", doc$fileid, "\n")
    cat("file:", doc$db_path, "\n")
    cat("docid:", doc$docid, "\n")
    cat("doc pages: ", doc$doc_pg_from, "-", doc$doc_pg_to, "\n", sep="")
    cat("\n")
    cat("MEETING INFO", "\n")
    cat("============", "\n")
    cat("jurisdiction:", doc$jurisdiction, "\n")
    if (!is.na(doc$mtg_year)) {
        cat("meeting date: ")
        cat(doc$mtg_year, doc$mtg_month, doc$mtg_day, sep="-")
        cat("\nmeeting date source: ", doc$mtg_dt_source)
    } else cat("meeting date: ERROR, NO DATE")
    cat("\n\n")
    cat("HEARING INFO", "\n")
    cat("============", "\n")
    cat("hearing #:", doc$hrgno, "\n")
    cat("hearing pages: ", doc$hrg_pg_from, "-", doc$hrg_pg_to, "\n", sep="")
    cat("hearing type:", doc$hrg_type, "\n")
    cat("accused: ", doc$hrg_accused, " (", doc$hrg_acc_uid ,")", "\n", sep="")
    cat("\n\n")
    cat("HEARING HEADER", "\n")
    cat("==============", "\n")
    cat(doc$hrg_head)
    cat("\n\n")
    cat("HEARING TEXT", "\n")
    cat("============", "\n")
    cat(doc$hrg_text)
    cat("\n")
    return(doc)
}

# }}}

out <- pmap(docs, list) %>%
    map(rptout) %>%
    map_dfr(as_tibble)

write_xlsx(out, args$output)

# done.
