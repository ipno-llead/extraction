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

# need to create shared links in order to create permalink,
# unless there one already exists, then use that

sharedlink_ls <- drop_list_shared_links(verbose=FALSE, dtoken=tok)
stopifnot("should have retrieved all links" = !sharedlink_ls$has_more)

sharedlinks <- map_dfr(sharedlink_ls$links,
                       ~tibble(sharelink=.$url, id=.$id))
# }}}

# dl from dropbox {{{
download <- function(id, output, dtoken) {
    if (file.exists(output)) return(TRUE)
    drop_download(id, local_path=output, dtoken=dtoken)
}

if (!dir.exists(args$outdir)) dir.create(args$outdir, recursive=TRUE)

downloaded <- to_dl %>%
    select(name, path_lower, path_display, id, content_hash) %>%
    mutate(outputname = paste(args$outdir, name, sep="/")) %>%
    mutate(downloaded = map2(id, outputname, safely(download), dtoken=tok))

stopifnot(
    "not all files downloaded" = map_lgl(downloaded$downloaded,
                                       ~if_else(is.null(.$error), .$result, FALSE))
)
# }}}

# add permalinks {{{
get_permalink <- function(db_id, dict) {
    res <- filter(dict, id==db_id)
    if (nrow(res) == 1) return(res$sharelink)
    share_resp <- safely(drop_share)(db_id, dtoken=tok)
    if (!is.null(share_resp$error)) return(share_resp$error$message)
    return(share_resp$url)
}

out <- downloaded %>%
    mutate(filesha1=map_chr(outputname, digest, file=TRUE, algo='sha1')) %>%
    select(db_path=path_display, db_id=id, db_content_hash=content_hash,
           local_name=outputname, sha1_hash=filesha1) %>%
    mutate(permalink=map_chr(db_id, get_permalink, dict=sharedlinks))
# }}}

outname <- paste(args$outdir, "index.csv", sep="/")
write_delim(out, outname, delim="|", na="")

# done.
