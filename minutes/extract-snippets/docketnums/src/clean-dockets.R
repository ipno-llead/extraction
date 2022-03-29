# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    stringr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "output/messy.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

dn <- read_parquet(args$input)

clean_docket <- function(docket) {
    dkt_ptrn <- c("DOCKETS?( NOS?\\.?)?", "DKT[.]?( NOS?[.]?)?", "#", "[:]") %>%
        paste0('(', ., ')', collapse='|')

    str_to_upper(docket) %>%
        str_squish %>%
        str_replace_all(dkt_ptrn, "") %>%
        str_squish %>%
        str_replace_all("[^0-9A-Z]", "")
}

tests <- c("Docket #20276"        = "20276",
           "Docket No. 20-246-"   = "20246",
           "Dkt. Nos. 16-223-S"   = "16223S",
           "Docket No.: C-672676" = "C672676")

stopifnot(all(clean_docket(names(tests)) == tests))

out <- dn %>%
    mutate(docket = clean_docket(docket)) %>%
    filter(docket != "")

write_parquet(out, args$output)

# done.
