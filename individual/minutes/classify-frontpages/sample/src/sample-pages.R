# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    readr,
    qpdf,
    stringr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../import/output/minutes.parquet")
parser$add_argument("--N", type="integer", default=5L)
parser$add_argument("--outstub", default="output/sampled-20210331")
args <- parser$parse_args()
# }}}

set.seed(19481210)
DB_TASK_PATH <- "../../../../dl-dropbox"
output_dir <- dirname(args$outstub)
working_dir <- paste0(output_dir, "/working")

pdf_out <- paste0(args$outstub, ".pdf")
labs_out <- paste0(args$outstub, ".csv")

pdfpgs <- function(input, pages, output, ...) pdf_subset(input, pages, output)

if (!dir.exists(working_dir)) dir.create(working_dir, recursive=TRUE)

pgs <- read_parquet(args$input)

samps <- pgs %>%
    mutate(filepath=str_extract(filename, "/output/.+$"),
           filepath=paste0(DB_TASK_PATH, filepath),
           region=str_match(filepath, "/output/([^/]+)/")[,2],
           samp_weight = if_else(pageno == 1, 2, 1)) %>%
    nest(data=-region) %>%
    mutate(data=map(data, sample_n, args$N, weight=samp_weight)) %>%
    unnest(data)

subsets <- samps %>%
    group_by(fileid, region, input=filepath) %>%
    summarise(pages=list(pageno), .groups='drop') %>%
    mutate(output=paste0(working_dir, "/", basename(input))) %>%
    mutate(subsetted_file=pmap_chr(., pdfpgs))

out <- subsets %>%
    unnest(pages) %>%
    transmute(fileid, region,
              filename=str_replace_all(input, "\\.\\./", ""),
              filename=str_match(filename, "/output/(.+)$")[,2],
              pg=pages, label=NA_character_)

pdf_combine(subsets$subsetted_file, output=pdf_out)
write_delim(out, labs_out, delim="|", na="")

