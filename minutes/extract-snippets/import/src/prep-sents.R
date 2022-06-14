# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    corpus,
    dplyr,
    stringr,
    tidyr
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../../extract/export/output/hearings.parquet")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

docs <- read_parquet(args$input) %>%
    filter(hrg_type %in% c("police", "unknown")) %>%
    replace_na(list(hrg_head = "", hrg_text = ""))


texts <- docs %>%
    transmute(docid, hrgno,
              text = paste(hrg_head, hrg_text) %>% str_squish) %>%
    mutate(seqid = seq_len(nrow(.)))

sents <- text_split(texts$text, units = "sentences")

splits <- as_tibble(sents[c("parent", "index")]) %>%
    mutate(sentence = as.character(sents$text),
           parent = as.integer(parent))

out <- texts %>%
    inner_join(splits, by = c("seqid" = "parent")) %>%
    transmute(docid, hrgno, sentence_id = index, sentence)

write_parquet(out, args$output)

# done.
