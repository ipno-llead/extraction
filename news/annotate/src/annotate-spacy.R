# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    spacyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

nw <- read_parquet(args$input)
# spacy_install()
spacy_initialize(model = "en_core_web_sm")

# tif format, see https://github.com/ropensci/tif
to_parse <- nw %>%
    transmute(doc_id = paste(fileid, pageno, sep = "_"),
              text)

parsed <- spacy_parse(to_parse,
                      lemma = FALSE,
                      entity = TRUE,
                      nounphrase = TRUE)

saveRDS(parsed, args$output)

# done.

