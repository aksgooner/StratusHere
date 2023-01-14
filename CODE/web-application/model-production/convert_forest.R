#### Script Information ####

# Team 105
# convert_forest.R

# This script is used to convert a random forest (or single decision tree) made
# in Python into an R list. Why would we want to do this? Starting a Python
# virtual environment on shinyapps.io is slow. By converting to a native R list,
# we can predict recursively using recursive Rcpp (C++) functions.

#### Setup ####

model_txt <- "model-production/model.txt"

library(dplyr)
library(magrittr)
library(purrr)
library(Rcpp)
library(stringr)

#### Convert Text Tree to Serialized List ####

# Read in tree
forest_df <- readr::read_csv(model_txt, col_names = "txt")
forest_split <- split(forest_df, cumsum(forest_df$txt == "septree"))
forest_split <- forest_split[1:(length(forest_split) - 1)]

# Convert to forest
forest <- purrr::map(
  .x = forest_split,
  .f = function(tree) {
    tree %>%
      dplyr::mutate(
        type = dplyr::case_when(
          stringr::str_detect(txt, "<=") ~ "l",
          stringr::str_detect(txt, ">") ~ "r",
          stringr::str_detect(txt, "class:") ~ "c",
          stringr::str_detect(txt, "septree") ~ "s"
        )
      ) %>%
      dplyr::filter(type %in% c("l", "c")) %>%
      dplyr::mutate(
        ind = stringr::str_count(txt, "\\|"),
        diff = abs(pmin(0, lead(ind) - ind)),
        last = dplyr::row_number() == max(dplyr::row_number()),
        txt = dplyr::case_when(
          type == "l" ~ stringr::str_replace_all(txt, c(
            "\\--- " = "list(col = '",
            " <=" = "', val = "
          )) %>% paste0(", left ="),
          type == "c" & !last ~ stringr::str_replace_all(txt, c(
            "\\|--- class: " = "list(col = '-1', val = "
          )) %>% paste0(stringr::str_dup(")", diff + 1), ", right ="),
          type == "c" & last ~ stringr::str_replace_all(txt, c(
            "\\|--- class: " = "list(col = '-1', val = "
          )) %>% paste0(")"),
          TRUE ~ txt
        ),
        open = stringr::str_count(txt, "\\("),
        close = stringr::str_count(txt, "\\)"),
        diff_close = stringr::str_dup(")", sum(open) - sum(close)),
        txt = dplyr::if_else(last, paste0(txt, diff_close), txt)
      ) %>%
      dplyr::pull(txt) %>%
      stringr::str_remove_all("\\|") %>%
      glue::glue_collapse(sep = "\n") %>%
      rlang::parse_expr() %>%
      eval()
    
  }
)

# Save to disk
readr::write_rds(forest, "model-production/model.Rds")
