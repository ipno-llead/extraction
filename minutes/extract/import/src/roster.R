# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    assertr,
    dplyr,
    readr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--personnel")
parser$add_argument("--event")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

# helpers {{{
mindt <- function(dt) {
    if (all(is.na(dt))) return(as.Date(NA))
    min(dt, na.rm=TRUE)
}

maxdt <- function(dt) {
    if (all(is.na(dt))) return(as.Date(NA))
    max(dt, na.rm=TRUE)
}
# }}}

# input data {{{
pers <- read_csv(args$personnel,
                 col_types= cols(.default     = col_character(),
                                  birth_year  = col_integer(),
                                  birth_month = col_integer(),
                                  birth_day   = col_integer()))

event <- read_csv(args$event, col_types = cols(.default = col_character()))
# }}}

# events -> officer start/stop dates {{{
ofcr_timeline <- event %>%
    filter(kind %in% c("officer_hire", "officer_left"),
           !is.na(year), !is.na(month), !is.na(day)) %>%
    assert(not_na, year, month, day) %>%
    mutate(event_dt = as.Date(paste(year, month, day, sep="-"))) %>%
    select(uid, event_uid, event_dt, kind, agency) %>%
    pivot_wider(names_from = kind, values_from = event_dt,
                values_fill = as.Date(NA)) %>%
    # if a uid has multiple hire/left events for the same agency,
    # this treats it as if they were there for the entire time
    group_by(uid, agency) %>%
    summarise(start = mindt(officer_hire),
              end   = maxdt(officer_left),
              .groups = "drop") %>%
    replace_na(list(start = as.Date("1800-01-01"),
                    end   = as.Date("2050-12-31")))
# }}}

out <- pers %>%
    select(uid, last_name, middle_name, middle_initial, first_name) %>%
    left_join(ofcr_timeline, by="uid")

write_parquet(out, args$output)

# done.
