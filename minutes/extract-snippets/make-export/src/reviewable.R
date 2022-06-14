library(writexl)
library(arrow)
library(tidyverse)

hrg <- read_parquet("output/hearing-snippets.parquet")

splits <- hrg %>%
    pivot_longer(cols = c(-docid, -hrgno, -docket)) %>%
    filter(!is.na(value)) %>%
    group_by(name) %>% group_split

splitnames <- map_chr(splits, ~unique(.$name))

splits <- splits %>% set_names(splitnames)

write_xlsx(splits, "output/hearing-snippets-review.xlsx")
