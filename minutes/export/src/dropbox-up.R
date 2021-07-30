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
    stringr,
    tidyr
)
# }}}

# command-line args {{{
parser <- ArgumentParser()
parser$add_argument("--pdfindex")
parser$add_argument("--txtindex")
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

drop_pdfs <- drop_dir(file.path(args$dbpath, "pdf")) %>%
    select(dbname = name, dbid = id, db_hash = content_hash)

drop_txts <- drop_dir(file.path(args$dbpath, "txt")) %>%
    select(dbname = name, dbid = id, db_hash = content_hash)

drop_files <- bind_rows(drop_pdfs, drop_txts)
pdfindex <- read_parquet(args$pdfindex)
txtindex <- read_parquet(args$txtindex)
index <- pdfindex %>% inner_join(txtindex, by = "docid") %>%
    pivot_longer(c(pdfname, txtname),
                 names_to = "filetype", values_to = "path") %>%
    mutate(filetype = str_replace(filetype, "name$", ""))

local_files <- index %>%
    transmute(docid,
              filetype,
              path,
              filename = basename(path),
              local_db_hash = drop_content_hash(path),
              local_sha1hash = map_chr(path, digest,
                                       algo="sha1", file = TRUE))
# }}}

# upload files that are new {{{
to_remove <- drop_files %>%
    anti_join(local_files, by = c("dbname" = "filename"))
if (nrow(to_remove) > 0)
    warning(str_glue("there are {nrow(to_remove)} files on dropbox that are no longer matched to a db file"),
            call. = FALSE)
# stopifnot(nrow(to_remove) == 0)

to_add <- local_files %>%
    left_join(drop_files, by = c("filename" = "dbname")) %>%
    filter(is.na(db_hash) | local_db_hash != db_hash) %>%
    mutate(dbpath = file.path(args$dbpath, filetype)) %>%
    distinct(path, dbpath)

message(str_glue("uploading {nrow(to_add)} files"))

walk2(to_add$path, to_add$dbpath, upload)
# }}}

done_drop_files <- drop_dir(args$dbpath, dtok=tok, recursive = TRUE)

indout <- index %>%
    distinct(docid, page_count) %>%
    inner_join(local_files, by = "docid") %>%
    inner_join(done_drop_files, by = c("filename" = "name")) %>%
    transmute(docid, page_count,
              filetype,
              db_path = path_display,
              db_id = id,
              db_content_hash = content_hash)

out <- indout %>%
    pivot_longer(c("db_path", "db_id", "db_content_hash"),
                 names_to = "col", values_to = "val") %>%
    transmute(docid, page_count,
              col = paste(filetype, col, sep="_"),
              val) %>% distinct %>%
    pivot_wider(names_from = col, values_from = val)

write_parquet(out, args$output)

# done.
