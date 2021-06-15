# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    dplyr,
    here,
    sentencepiece
)
# }}}

# args {{{
parser <- ArgumentParser()
parser$add_argument("--input", default = "../features/output/minutes-features.parquet")
parser$add_argument("--modeldir", default = "output/tokenizer")
args <- parser$parse_args()
# }}}

# set up directory {{{
if (!dir.exists(args$modeldir))
    dir.create(args$modeldir, recursive = TRUE)

modeldir <- normalizePath(args$modeldir)
# }}}

mins <- read_parquet(args$input)
trainfile <- file.path(modeldir, "spm-train.txt")
writeLines(mins$text, trainfile)

model <- sentencepiece(
    trainfile,
    type = "bpe",
    coverage = .999,
    vocab_size = 5000,
    threads = 8,
    model_dir = modeldir,
    model_prefix = "spm")
