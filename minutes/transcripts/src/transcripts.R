# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    readr,
    stringr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--docs", default = "../import/export/output/minutes.parquet")
parser$add_argument("--meta", default = "../import/export/output/metadata.csv")
args <- parser$parse_args()
# }}}

mins <- read_parquet(args$docs)

meta <- read_delim(args$meta, delim="|", na="",
                   col_types = cols(.default = col_character(),
                                    year = col_integer(),
                                    month = col_integer(),
                                    day = col_integer()))

meta %>%
    filter(file_category == "transcript",
           region == "orleans") %>%
    sample_n(3) %>%
    select(filepath)
    distinct(region, fileid) %>% count(region)
    left_join(mins, by = "fileid") %>%
    select(fileid, text) %>%
    mutate(text = str_squish(str_to_lower(text)),
           text = str_replace_all(text, "^([0-9]+\\W)+", "") %>% str_squish)
