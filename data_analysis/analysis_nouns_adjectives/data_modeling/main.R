source(file.path('./analysis_nouns_adjectives/data_modeling', 'data_preparation.R'))
source(file.path('./analysis_nouns_adjectives/data_modeling', 'models.R'))


DATASET<- 'nouns_adjectives.csv'
MODEL_FOLDER <- './analysis_nouns_adjectives/output/models'
MODEL_NAME <- 'bayes_model_mt_sp_dss_affix_effect.rds'


main_preparation <- function() {
  dat <- read.csv(file.path('../data', DATASET), sep = '\t')
  dat_prepared <- prepare_data_pipeline(dat, 'scroll', 'NO')
  return(dat_prepared)
}


model_data <- function(df_prepared, formula, warmup, iter, adapt_delta) {
  
  brm_model <- fit_brm_model(df_prepared, 
                             formula, 
                             warmup, iter, adapt_delta)
  save_model(brm_model, MODEL_FOLDER, MODEL_NAME)
}


dat <- main_preparation()
print(dim(dat))

model_data(dat, 
           formula_mt_sp_dss, 
           6000, 12000, 0.95)
summary(brm_model)
