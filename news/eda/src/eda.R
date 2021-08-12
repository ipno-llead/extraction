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
parser$add_argument("--input", default = "../import/export/output/news.parquet")
args <- parser$parse_args()
# }}}

nw <- read_parquet(args$input)
# spacy_install()
spacy_initialize(model = "en_core_web_sm")

parsed <- spacy_parse(nw$text, lemma = FALSE, entity = TRUE, nounphrase = TRUE)

tibble(parsed) %>% filter(doc_id == "text108", sentence_id <= 3) %>%
    print(n = 50)

title_match <- tibble(parsed) %>%
    arrange(doc_id, sentence_id, token_id) %>%
    filter(sentence_id < 15) %>%
    mutate(named_person = str_detect(entity, "^PERSON_")) %>%
    group_by(doc_id, sentence_id) %>%
    filter(named_person | (pos == "PROPN" & lead(named_person))) %>%
    ungroup %>% filter(!named_person) %>%
    filter(str_to_lower(token) %in% c("officer", "trooper", "police", "detective", "sergeant")) %>%
    distinct(doc_id, sentence_id, start_pos = token_id)

extracted <- entity_extract(parsed, type = "all") %>% tibble %>%
    filter(entity_type == "PERSON") %>%
    inner_join(title_match, by = c("doc_id", "sentence_id"))

extracted_entities <- nw %>%
    mutate(doc_id = paste0("text", seq_len(nrow(.)))) %>%
    inner_join(extracted, by = "doc_id") %>%
    select(fileid, pageno, text, entity) %>%
    distinct %>% mutate(entity_id = seq_len(nrow(.))) %>%
    mutate(entity = str_split(entity, "_")) %>%
    unnest(entity)

roster <- read_parquet("../../minutes/extract/import/output/roster.parquet")

extracted_entities %>%
    left_join(roster %>%
                  select(uid, last_name, first_name) %>%
                  pivot_longer(cols = -uid,
                               names_to = "name_type",
                               values_to = "name"),
    by = c("entity" = "name")) %>%
    distinct(fileid, entity_id, uid, name_type, name = entity) %>%
    group_by(fileid, entity_id, uid) %>% filter(n() > 1) %>% ungroup %>%
    distinct(fileid, uid)

extracted_uid <- roster %>% select(uid, last_name, first_name) %>%
    pivot_longer(cols = -uid, names_to = "name_type", values_to = "name") %>%
    inner_join(extracted_entities, by = c("name" = "entity")) %>%
    distinct(fileid, entity_id, uid, name_type, name) %>%
    group_by(fileid, entity_id, uid) %>% filter(n() > 1) %>% ungroup %>%
    distinct(fileid, uid)


out <- nw %>%
    inner_join(extracted_uid, by = "fileid") %>%
    left_join(roster %>% select(uid, first_name, last_name, agency),
               by = "uid") %>%
    group_by(fileid, uid, first_name, last_name, agency) %>%
    summarise(text = paste(text, collapse = "\n\n"), .groups = "drop")

nw %>%
    anti_join(out, by = "fileid") %>%
    filter(pageno == 1) %>%
    sample_n(1) %>% pluck("text") %>% cat("\n\n###\n\n")
