# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    readr,
    tidyr,
    writexl
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--minutes", default = "../export/output/minutes.parquet")
parser$add_argument("--meta", default = "../../import/export/output/metadata.csv")
parser$add_argument("--docs", default = "output/sampled-docids.txt")
parser$add_argument("--traindir", default = "output/training-data")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# read data {{{
docids <- readLines(args$docs)
docs <- read_parquet(args$minutes) %>% filter(docid %in% docids)
meta <- read_delim(args$meta, delim="|",
                   col_types = cols(.default = col_character())) %>%
    transmute(fileid, filename = basename(db_path), db_path) %>% distinct

# }}}

# helpers {{{
export <- function(docid, doc) {
    outname <- paste0(args$traindir, "/", docid, "-",
                      format(Sys.Date(), "%Y%m%d"), ".xlsx")
    output <- tibble(docid = docid, doc)
    write_xlsx(output, outname)
}
# }}}

formatted <- docs %>%
    inner_join(meta, by = "fileid") %>%
    select(filename, db_path, fileid, pageno, docid, docpg,
           lineno, text, predicted = linetype) %>%
    nest(data = -docid)

exported <- formatted %>%
    mutate(sample_file = map2_chr(docid, data, export) %>% basename)

out <- exported %>%
    unnest(data) %>%
    group_by(docid) %>%
    summarise(
        orig_filename = unique(filename),
        db_path = unique(db_path),
        fileid = unique(fileid),
        doc_pg_from = min(pageno), doc_pg_to = max(pageno),
        sample_file = unique(sample_file),
        hearing_detected = any(predicted %in% c("hearing", "hearing_header")),
        .groups = 'drop')

write_xlsx(out, args$output)

# done.
