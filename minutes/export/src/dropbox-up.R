# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    arrow,
    digest,
    dplyr,
    purrr,
    rdrop2,
    stringr
)
# }}}

# command-line args {{{
parser <- ArgumentParser()
parser$add_argument("--index")
parser$add_argument("--token")
parser$add_argument("--dbpath")
parser$add_argument("--output")
args <- parser$parse_args()
# }}}

upload <- function(localfile, dbpath) {
    drop_upload(localfile, dbpath, mode="overwrite", autorename = FALSE)
}

# load data {{{
tok <- readRDS(args$token)

drop_files <- drop_dir(args$dbpath, dtoken=tok) %>%
    select(dbname = name, dbid = id, db_hash = content_hash)

index <- read_parquet(args$index)

local_files <- index %>%
    transmute(docid,
              path = pdfname,
              filename = basename(path),
              local_db_hash = drop_content_hash(path),
              local_sha1hash = map_chr(path, digest,
                                       algo="sha1", file = TRUE))
# }}}

# upload files that are new {{{
to_remove <- drop_files %>%
    anti_join(local_files, by = c("dbname" = "filename"))
stopifnot(nrow(to_remove) == 0)

to_add <- local_files %>%
    left_join(drop_files, by = c("filename" = "dbname")) %>%
    filter(is.na(db_hash) | local_db_hash != db_hash) %>%
    pluck("path")

walk(to_add, upload, dbpath = args$dbpath)
# }}}

done_drop_files <- drop_dir(args$dbpath, dtok=tok)

out <- index %>%
    inner_join(local_files, by = c("docid", "pdfname" = "path")) %>%
    inner_join(done_drop_files, by = c("filename" = "name")) %>%
    transmute(docid, page_count,
              fileid = str_sub(local_sha1hash, 1, 7),
              file_db_path = path_display,
              file_db_id = id,
              file_db_content_hash = content_hash)

write_parquet(out, args$output)

# done.
