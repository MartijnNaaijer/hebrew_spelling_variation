library(tidyverse)
list.files()
source(file.path('./analysis_nouns_adjectives', 'config.R'))

FACTOR_COLUMNS <- c('has_prefix', 'has_prs', 'has_nme', 'has_hloc', 
                    'has_suffix', 'neigh_vowel_letter','lex', 'book', 
                    'has_vowel_letter', 'lex_type', 'law_phase', 'law_phase2', 'scroll',
                    'scr_book2', 'qsp', 'qsp_sp')


prepare_data_pipeline <- function(df, col_name, values) {
  
  df <- df %>%
    make_has_suffix_column %>%
    make_type2_column %>%
    make_lex_type_column %>%
    make_second_book_column %>%
    make_law_phase_column %>%
    make_law_phase2_column %>%
    make_second_book_column %>%
    split_great_scroll %>%
    make_scroll_book2_column %>%
    make_qsp_column %>%
    make_qsp_sp_column %>%
    select_data(col_name, values) %>%
    reorder_syllable_type_levels %>%
    select_lex_type_data_with_variation %>%
    make_factor_columns(FACTOR_COLUMNS)
  
  return(df)
}

make_type2_column <- function(df) {
  df$type2 <- ifelse(df$type %in% c('single', 'last'), 'last', 'first')
  df$type2 <- factor(df$type2, levels = c('last', 'first'))
  return(df)
}

make_has_suffix_column <- function(df) {
  df$has_suffix <- as.factor(as.numeric(df$has_prs | df$has_nme | df$has_hloc))
  return(df)
}

make_factor_columns <- function(df, column_names) {
  
  df <- df %>% mutate_at(column_names, as.factor)
  return(df)
}


make_lex_type_column <- function(df) {
  
  df$lex_type <- paste(df$lex, df$type2, sep='_')
  return(df)
}


make_second_book_column <- function(df) {
  df$book2 <- df$book %>% str_replace('1_', '') %>% str_replace('2_', '')
  return(df)
}


make_scroll_book2_column <- function(df) {
  df$scr_book2 <- paste(df$scroll, df$book2, sep='_')
  return(df)
}
  

make_law_phase_column <- function(df) {
  
  df$law_phase <- ifelse(df$book %in% LAW_BOOKS, 0, 
                          ifelse(df$book %in% EBH_BOOKS, 1, 
                          ifelse(df$book %in% LBH_BOOKS, 2, 3)))
  return(df)
}


make_qsp_column <- function(df) {
  df$qsp <- ifelse(df$scroll %in% QSP_SCROLLS, 1, 0)
  return(df)
}


make_qsp_sp_column <- function(df) {
  df$qsp_sp <- ifelse(df$qsp == 1, 'QSP', 
                      ifelse(df$scroll == 'SP', 'SP', 
                             'Other'))
  return(df)
}

  
split_great_scroll <- function(df) {
  df$scroll <- ifelse(df$scroll == '1Qisaa' & df$chapter < 34, '1QisaaI', 
                       ifelse(df$scroll == '1Qisaa' & df$chapter > 33, '1QisaaII', 
                              df$scroll))
  return(df)
}

make_law_phase2_column <- function(df) {
  df$law_phase2 <- ifelse(df$book %in% LAW_BOOKS & df$scroll == 'MT', 0,
                           ifelse(df$book %in% LAW_BOOKS & df$scroll == 'SP', 1,
                                  ifelse(df$book %in% EBH_BOOKS, 2, 
                                         ifelse(df$book %in% LBH_BOOKS, 3, 
                                                4))))
  
  return(df)
  
}


select_data <- function(df, col_name, values) {
  # Select scrolls in vector values.
  # In case values is 'NO', the whole df is returned.
  
  if (values == 'NO') {return(df)} 
  else {
    df <- df %>% filter(!!as.symbol(col_name) %in% values)
  }
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
  dat_var <- droplevels(mt_var)
  
  return(df_var)
}


