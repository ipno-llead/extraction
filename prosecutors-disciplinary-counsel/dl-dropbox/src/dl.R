# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

# load libs {{{
pacman::p_load(
    argparse,
    assertr,
    digest,
    dplyr,
    here,
    purrr,
    rdrop2,
    readr,
    stringr,
    tidyr,
    tools
)
# }}}

# command-line args {{{
parser <- ArgumentParser()
parser$add_argument("--path")
parser$add_argument("--token")
parser$add_argument("--outdir")
args <- parser$parse_args()
# }}}

# load data {{{
tok <- readRDS(args$token)
to_dl <- drop_dir(args$path, recursive = TRUE) %>%
    filter(.tag == "file")
# }}}

# dl from dropbox {{{
download <- function(id, output, dtoken) {
    if (file.exists(output)) return(TRUE)
    drop_download(id, local_path=output, dtoken=dtoken)
}

if (!dir.exists(args$outdir)) dir.create(args$outdir, recursive=TRUE)

to_dl <- to_dl %>%
    filter(str_detect(path_lower, regex("\\.pdf", ignore_case = TRUE))) %>%
    mutate(fn = str_replace(path_lower, str_to_lower(args$path), ""),
           fn = str_replace_all(fn, "^/+", ""),
           fn = str_replace_all(fn, "\\s+", "-")) %>%
    select(name, path_lower, path_display, id, content_hash, fn) %>%
    mutate(outputname = file.path(args$outdir, fn))

to_dl$outputname %>% dirname %>% unique %>% walk(dir.create, recursive = T) %>%
    invisible

downloaded <- to_dl %>%
    mutate(downloaded = map2(id, outputname, safely(download), dtoken=tok))

stopifnot(
    "not all files downloaded" = map_lgl(downloaded$downloaded,
                                       ~if_else(is.null(.$error), .$result, FALSE))
)
# }}}

out <- downloaded %>%
    mutate(filesha1=map_chr(outputname, digest, file=TRUE, algo='sha1')) %>%
    transmute(db_path=path_display, db_id=id, db_content_hash=content_hash,
              local_name=outputname, filesha1, fileid = str_sub(filesha1, 1, 7))

outname <- paste(args$outdir, "index.csv", sep="/")
write_delim(out, outname, delim="|", na="")

# done.
