library(tidyverse)
list.files()
source(file.path('./analysis_nouns_adjectives', 'config.R'))

FACTOR_COLUMNS <- c('has_prefix', 'has_prs', 'has_nme', 'lex', 'book', 
                    'has_vowel_letter', 'lex_type', 'law_phase', 'scroll')

prepare_data_pipeline <- function(df) {
  
  df <- df %>% make_lex_type_column %>%
    make_column_book_second %>%
    make_law_phase_column %>%
    make_second_book_column %>%
    make_law_phase_column %>%
    split_great_scroll %>%
    reorder_syllable_type_levels %>%
    select_lex_type_data_with_variation %>%
    make_factor_columns(FACTOR_COLUMNS)
  
  return(df)
}

make_factor_columns <- function(df, column_names) {
  
  df <- df %>% mutate_at(column_names, as.factor)
  return(df)
}


make_lex_type_column <- function(df) {
  
  df$lex_type <- paste(df$lex, df$type, sep='_')
  return(df)
}


make_second_book_column <- function(df) {
  df$book2 <- df$book %>% str_replace('1_', '') %>% str_replace('2_', '')
  return(df)
}


make_law_phase_column <- function(df) {
  
  df$law_phase <- ifelse(df$book %in% LAW_BOOKS, 0, 
                          ifelse(df$book %in% EBH_BOOKS, 1, 
                          ifelse(df$book %in% LBH_BOOKS, 2, 3)))
  return(df)
}

  
split_great_scroll <- function(df) {
  df$scroll <- ifelse(df$scroll == '1Qisaa' & df$chapter < 34, '1QisaaI', 
                       ifelse(df$scroll == '1Qisaa' & df$chapter > 33, '1QisaaII', 
                              df$scroll))
  return(df)
}


reorder_syllable_type_levels <- function(df) {
  df$type <- factor(df$type, levels = c('last', 'first', 'single'))
  return(df)
}


select_lex_type_data_with_variation <- function(df) {
  variation_lex_type_list <- list()
  
  for (lex_t in unique(df$lex_type)) {
    lex_type_df <- df %>% filter(lex_type == lex_t)
    lt_vowels <- lex_type_df$has_vowel_letter %>% unique()
    if (length(lt_vowels) > 1) {
      variation_lex_type_list[[lex_t]] <- lex_type_df
    }
  }
  
  df_var <- do.call('rbind', variation_lex_type_list)
  
  return(df_var)
}


