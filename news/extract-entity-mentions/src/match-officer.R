# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    stringr,
    stringdist,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--mentions", default = "output/candidate-officer-names.parquet")
parser$add_argument("--roster", default = "../import/export/output/roster.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

candidates <- read_parquet(args$mentions)
roster <- read_parquet(args$roster)

candidate_tokens <- candidates %>%
    transmute(fileid, title,
              candidate_name = str_to_lower(name),
              token = str_split(candidate_name, boundary("word"))) %>%
    unnest(token)

roster_tokens <- roster %>%
    mutate(roster_name = str_to_lower(paste(first_name, last_name))) %>%
    distinct(uid, roster_name, last_name, first_name) %>%
    pivot_longer(cols = c(last_name, first_name),
                 names_to = "type",
                 values_to = "token") %>%
    mutate(token = str_to_lower(token))

out <- candidate_tokens %>%
    inner_join(roster_tokens, by = "token") %>%
    group_by(fileid, title, candidate_name, roster_name, uid) %>%
    filter(n_distinct(type) > 1) %>% ungroup %>%
    distinct(fileid, uid, candidate_name, title, roster_name)

write_parquet(out, args$output)

# done.
