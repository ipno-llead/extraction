# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    readr,
    readxl,
    qpdf,
    stringr,
    tidyr,
    writexl
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../import/output/minutes.parquet")
parser$add_argument("--meta", default = "../../ocr/output/index.csv")
parser$add_argument("--frozendir", default = "frozen")
parser$add_argument("--N", type="integer", default=5L)
parser$add_argument("--outstub", default="output/sampled-20210331")
args <- parser$parse_args()
# }}}

set.seed(19481210)
DB_TASK_PATH <- "../../../../dl-dropbox"
output_dir <- dirname(args$outstub)
working_dir <- paste0(output_dir, "/working")

pdf_out <- paste0(args$outstub, ".pdf")
labs_out <- paste0(args$outstub, ".xlsx")

sent_files <- list.files(args$frozendir, full.names=TRUE, pattern="*.xlsx")

if (length(sent_files) > 0) {
    already <- map_dfr(sent_files, read_xlsx) %>% select(fileid, pageno=pg)
} else {
    already <- tibble(fileid=character(), pageno=integer())
}

pdfpgs <- function(input, pages, output, ...) pdf_subset(input, pages, output)

if (!dir.exists(working_dir)) dir.create(working_dir, recursive=TRUE)

pgs <- read_parquet(args$input) %>%
    anti_join(already, by=c("fileid", "pageno"))
meta <- read_delim(args$meta, delim="|",
                   col_types=cols(.default=col_character()))

samps <- pgs %>%
    mutate(filepath=str_extract(filename, "/output/.+$"),
           filepath=paste0(DB_TASK_PATH, filepath),
           region=str_match(filepath, "/output/([^/]+)/")[,2],
           samp_weight = if_else(pageno == 1, 2, 1)) %>%
    nest(data=-region) %>%
    mutate(sampsize=pmin(args$N, map_int(data, nrow))) %>%
    mutate(data=map2(data, sampsize, sample_n, weight=samp_weight)) %>%
    unnest(data)

subsets <- samps %>%
    group_by(fileid, region, input=filepath) %>%
    summarise(pages=list(pageno), .groups='drop') %>%
    mutate(output=paste0(working_dir, "/", basename(input))) %>%
    mutate(subsetted_file=pmap_chr(., pdfpgs))

# pgs <- meta %>%
#     mutate(fileid=str_sub(filesha1, 1, 7)) %>%
#     select(fileid, db_path) %>%
#     inner_join(pgs, by="fileid")

fileinfo <- meta %>% 
    mutate(fileid=str_sub(filesha1, 1, 7)) %>%
    select(fileid, db_path)

out <- subsets %>%
    inner_join(fileinfo, by="fileid") %>%
    unnest(pages) %>%
    transmute(fileid, region, db_path,
              #               filename=str_replace_all(input, "\\.\\./", ""),
              #               filename=str_match(filename, "/output/(.+)$")[,2],
              pg=pages, label=NA_character_, notes=NA_character_) %>%
    mutate(sampled_pdf=paste0(basename(args$outstub), ".pdf"),
           sampled_pdf_pg=seq_len(nrow(.)))

pdf_combine(subsets$subsetted_file, output=pdf_out)
write_xlsx(out, labs_out)

# done.
