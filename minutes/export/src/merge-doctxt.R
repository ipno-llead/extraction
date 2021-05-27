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
parser$add_argument("--docs")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

ind <- read_parquet(args$index)
hrg <- read_parquet(args$hearings)
docs <- read_parquet(args$docs)

doctxt <- docs %>%
    arrange(docid, fileid, pageno) %>%
    group_by(docid) %>%
    summarise(ocr_text = paste(text, collapse="\n"), .groups="drop") %>%
    mutate(ocr_text = str_replace_all(ocr_text, "(\n[ ]*){3,}", "\n\n"),
           ocr_text = str_trim(ocr_text))

hearings <- hrg %>%
    transmute(docid,
           year = mtg_year,
           month = mtg_month,
           day = mtg_day,
           dt_source = mtg_dt_source,
           hrg_no = hrgno,
           accused = hrg_accused,
           matched_uid = hrg_acc_uid,
           hrg_text = paste(hrg_head, hrg_text, sep="\n"))

out <- ind %>%
    inner_join(hearings, by = "docid") %>%
    inner_join(doctxt, by = "docid")

write_csv(out, args$output)

# done.
