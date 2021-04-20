# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    assertr,
    dplyr,
    readr,
    logger,
    purrr,
    stringr,
    tidyr,
    udpipe,
    writexl
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input")
parser$add_argument("--index")
parser$add_argument("--roster")
parser$add_argument("--tagger", default = "frozen/english-ewt-ud-2.4-190531.udpipe")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

docs <- read_parquet(args$input) %>% rename(pg=pageno)
tagger <- udpipe_load_model(file=args$tagger)
index <- read_delim(args$index, delim="|", na="",
                    col_types = cols(.default=col_character())) %>%
    mutate(fileid = str_sub(filesha1, 1, 7))
roster <- readr::read_csv("input/roster.csv",
                col_types = cols(.default=col_character())) %>%
    distinct(uid, last_name, middle_name, middle_initial, first_name)

stopifnot(length(unique(roster$uid)) == nrow(roster))
stopifnot(!any(is.na(roster$uid)))

# docs2chunks {{{
pad_num <- function(num) str_pad(num, 4, side="left", pad="0")

chunks <-  docs %>%
    mutate(chunk=str_split(text, "\n{2,}")) %>%
    unnest(chunk) %>%
    group_by(fileid, pg) %>%
    mutate(chunkid=seq_along(chunk),
           chunkid=paste(fileid, pad_num(pg), pad_num(chunkid),
                         sep="_")) %>%
    ungroup %>%
    select(fileid, pg, chunkid, chunk) %>%
    mutate(chunk=str_replace_all(chunk, "\n", " ") %>% str_squish)
# }}}

log_info("starting annotation...")
docs_parsed <- udpipe_annotate(tagger, chunks$chunk,
                               parser="default", trace=250,
                               doc_id=chunks$chunkid)
log_info("done annotating")

docs_parsed <- as.data.frame(docs_parsed) %>% tibble %>%
    mutate(token_id=as.integer(token_id)) %>%
    separate(doc_id, into=c("fileid", "pg", "chunkid")) %>%
    mutate(pg=as.integer(pg), chunkid=as.integer(chunkid))

# get proper names{{{
propn <- docs_parsed %>%
    filter(upos == "PROPN") %>%
    group_by(fileid, pg, chunkid) %>%
    mutate(prv_word = lag(token_id, 1, default = -1L)) %>%
    mutate(new_entity = prv_word != token_id - 1L) %>%
    mutate(entity_id = cumsum(new_entity)) %>%
    group_by(fileid, pg, chunkid, entity_id) %>%
    summarise(name = paste(token, collapse = " "), .groups="drop")
# }}}

# prep statewide roster data {{{
# note: ignoring middle names for now
roster_xref <- roster %>%
    select(uid, first_name, last_name) %>%
    mutate(across(c(first_name, last_name),
                  ~replace_na(str_to_lower(.), ""))) %>%
    mutate(fullname=paste(first_name, last_name),
           fullname=str_squish(fullname)) %>%
    pivot_longer(cols=c(-uid, -fullname),
                 names_to="tokentype", values_to="name")
# }}}

# match {{{
# to do -- match based on string similarity to catch slight differences
log_info("starting match")
matched <- propn %>%
    mutate(candidate=str_to_lower(name)) %>%
    filter(!str_detect(candidate, "(\\W|^)council(\\W|$)")) %>%
    select(-name) %>%
    mutate(token=str_split(candidate, "\\s+")) %>%
    filter(map_int(token, length) <= 5) %>%
    unnest(token) %>%
    distinct(fileid, pg, chunkid, entity_id, candidate, token) %>%
    group_by(fileid, pg, chunkid, entity_id) %>%
    mutate(tokenid = seq_along(token)) %>% filter(n() > 1) %>%
    ungroup %>%
    inner_join(rename(roster_xref, canon=fullname),
               by=c(token="name")) %>%
    group_by(fileid, pg, chunkid, entity_id, uid) %>%
    filter(n() > 1) %>% ungroup %>%
    distinct(fileid, pg, candidate, uid)
log_info("done matching")
# }}}

log_info(distinct(matched, fileid) %>% nrow, " documents processed (",
         distinct(matched, fileid, pg) %>% nrow, " pages)")
log_info(nrow(matched), " distinct matches")
log_info(distinct(matched, uid) %>% nrow, " unique ppl matched")

log_info("joining to metadata files for export")
out <- matched %>%
    inner_join(index,by="fileid") %>%
    select(fileid, db_path, pg, candidate, uid) %>%
    inner_join(roster, by="uid") %>%
    verify(nrow(.) == nrow(matched))

write_xlsx(out, args$output)

# done.
