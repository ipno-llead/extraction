# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    spacyr,
    stringr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--annotations")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

annotations <- readRDS(args$annotations)

titles <- c("officer",
            "sgt",
            "chief",
            "cpt",
            "capt",
            "captain",
            "gen",
            "gen.",
            "col",
            "director",
            "sheriff",
            "judge",
            "trooper",
            "police",
            "detective",
            "sergeant")

re_titles <- paste0("(^|\\W+)(", titles, ")(\\W+|$)", collapse = "|")

people <- entity_consolidate(annotations, concatenator = " ") %>% tibble %>%
    separate(doc_id, into = c("fileid", "pageno"), sep = "_") %>%
    filter(! pos %in% c("SPACE", "PUNCT")) %>%
    mutate(pageno = as.integer(pageno),
           title_match = str_to_lower(token) %in% titles,
           person = entity_type == "PERSON") %>%
    arrange(fileid, pageno, sentence_id, token_id) %>%
    group_by(fileid) %>%
    filter(person | (title_match & lead(person))) %>%
    mutate(token = if_else(lag(pos, default = "ENTITY") != "ENTITY",
                           paste(lag(token), token), token)) %>%
    ungroup

out <- people %>% filter(entity_type == "PERSON") %>%
    mutate(title = str_detect(token, regex(re_titles, ignore_case = TRUE))) %>%
    distinct(fileid, name = token, title)

write_parquet(out, args$output)

# done.
