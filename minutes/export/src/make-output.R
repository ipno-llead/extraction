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
    readr,
    stringr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--index")
parser$add_argument("--hearings")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

ind <- read_parquet(args$index)
hrg <- read_parquet(args$hearings)

hearings <- hrg %>%
    transmute(docid,
              year = mtg_year,
              month = mtg_month,
              day = mtg_day,
              dt_source = mtg_dt_source,
              hrg_no = hrgno,
              accused = hrg_accused,
              matched_uid = hrg_acc_uid,
              hrg_text = paste(hrg_head, hrg_text, sep="\n"),
              title = str_glue("Appeal hearing: {hrg_accused}",
                               " on {str_c(year, month, day, sep='-')}",
                               .na = "(unknown)"),
              agency = NA_character_)

out <- ind %>%
    inner_join(hearings, by = "docid")

write_csv(out, args$output, na = "")

# done.
