# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    digest,
    purrr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--hearings",
                    default = "../import/output/hearings.parquet")
parser$add_argument("--dockets",
                    default = "../docketnums/output/hearings-dockets.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

make_uid <- function(docket, accused) {
    digest(paste(docket, accused, sep = ", "),
           algo = "md5", serialize = FALSE)
}

# tested using `md5 -s "12345, john doe"` in bash
stopifnot(make_uid("12345", "john doe") == "e7b82260e9542d22edc4d5560571965f")

hrg <- read_parquet(args$hearings)
dn <- read_parquet(args$dockets)

# uid is docketnum+accused_uid
# if docketnum is missing, then use hrg_dt

out <- hrg %>%
    left_join(dn, by = c("docid", "hrgno")) %>%
    filter(!is.na(hrg_acc_uid), !is.na(docket)) %>%
    select(docid, hrgno, hrg_acc_uid, docket,
           mtg_year, mtg_month, mtg_day) %>%
    mutate(hrg_uid = map2_chr(hrg_acc_uid, docket, make_uid)) %>%
    select(docid, hrgno, hrg_uid)

write_parquet(out, args$output)

# done.
