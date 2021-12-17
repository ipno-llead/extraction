# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:
# Authors:     TS
# Maintainers: TS
# Copyright:   2021, HRDAG, GPL v2 or later
# =========================================

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    assertr,
    dplyr,
    readr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input",
                    default = "../../segment/export/output/minutes.parquet")
parser$add_argument("--agencies", default = "hand/agencies.csv")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

mins <- read_parquet(args$input)
agencies <- read_delim(args$agencies, delim = "|", col_types = "ccc") %>%
    distinct(jurisdiction, agency)

out <- mins %>%
    inner_join(agencies, by = c("f_region" = "jurisdiction")) %>%
    verify(nrow(.) == nrow(mins)) %>%
    mutate(agency = coalesce(agency, f_region)) %>%
    select(-f_region)

write_parquet(out, args$output)

# done.
