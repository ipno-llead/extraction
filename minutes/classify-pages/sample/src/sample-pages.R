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
parser$add_argument("--meta", default = "../../import/index/output/metadata.csv")
parser$add_argument("--frozendir", default = "frozen")
parser$add_argument("--N", type="integer", default=10L)
parser$add_argument("--outstub", default="output/sampled-20210331")
args <- parser$parse_args()
# }}}

set.seed(19481210)
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

all_regions <- meta %>% distinct(region)

regions_with_samps <- already %>% distinct(fileid) %>%
    inner_join(meta, by = "fileid") %>%
    distinct(region) %>%
    # want to take another look at kenner due to some weird formats
    filter(region != "kenner")

regions_without_samps <- all_regions %>%
    anti_join(regions_with_samps, by = "region") %>%
    pluck("region") %>% unique

samps <- pgs %>%
    filter(f_cat == "minutes") %>%
    inner_join(meta,by="fileid") %>%
    filter(region %in% regions_without_samps,
           filetype == "pdf") %>%
    mutate(filepath=here::here(str_replace(filepath, "^[^/]+/", ""))) %>%
    nest(data=c(-f_region)) %>%
    mutate(sampsize=pmin(args$N, map_int(data, nrow))) %>%
    mutate(data=map2(data, sampsize, sample_n)) %>%
    unnest(data)

subsets <- samps %>%
    group_by(fileid, f_region, f_cat, input=filepath) %>%
    summarise(pages=list(pageno), .groups='drop') %>%
    mutate(output=paste0(working_dir, "/", basename(input))) %>%
    mutate(subsetted_file=pmap_chr(., pdfpgs))

fileinfo <- meta %>% 
    select(fileid, db_path)

out <- subsets %>%
    inner_join(fileinfo, by="fileid") %>%
    unnest(pages) %>%
    transmute(fileid, f_region, f_cat, db_path,
              #               filename=str_replace_all(input, "\\.\\./", ""),
              #               filename=str_match(filename, "/output/(.+)$")[,2],
              pg=pages, label=NA_character_, notes=NA_character_) %>%
    mutate(sampled_pdf=paste0(basename(args$outstub), ".pdf"),
           sampled_pdf_pg=seq_len(nrow(.)))

pdf_combine(subsets$subsetted_file, output=pdf_out)
write_xlsx(out, labs_out)

# done.
