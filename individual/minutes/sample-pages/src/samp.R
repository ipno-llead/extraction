# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

pacman::p_load(
    argparse,
    arrow,
    dplyr,
    purrr,
    qpdf,
    readr,
    tidyr
)


parser <- ArgumentParser()
parser$add_argument("--input", default="../ocr/output/minutes.parquet")
parser$add_argument("--sampsize", type="integer", default=15L)
parser$add_argument("--outputdir", default="output")
args <- parser$parse_args()

docs <- read_parquet(args$input)

samps <- docs %>%
    distinct(fileid, filename, pageno) %>%
    mutate(region=strsplit(filename, "/"),
           region=map_chr(region, 6)) %>%
    nest(data=-region) %>%
    mutate(sampled=map(data, sample_n, args$sampsize)) %>%
    select(sampled) %>% unnest(sampled)

subsets <- samps %>%
    group_by(input=filename) %>%
    summarise(pages=list(pageno), .groups='drop') %>%
    mutate(output=paste0(args$outputdir, "/", basename(input))) %>%
    mutate(subsetted_file=pmap_chr(., pdf_subset)) %>%
    # shuffle
    sample_frac(1)

pdf_combine(subsets$subsetted_file,
            output=paste0(args$outputdir, "/", "sampled.pdf"))

# done.
