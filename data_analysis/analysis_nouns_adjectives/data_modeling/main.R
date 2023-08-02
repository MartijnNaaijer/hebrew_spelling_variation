source(file.path(scripts_folder, 'data_preparation.R'))
source(file.path(scripts_folder, 'models.R'))


DATASET<- 'nouns_adjectives.csv'
MODEL_FOLDER <- './analysis_nouns_adjectives/output/models'
MODEL_NAME <- 'bayes_model_mt_var7.rds'

main <- function() {
  
  dat <- read.csv(file.path('../data', DATASET), sep = '\t')
  dat_prepared <- prepare_data_pipeline(dat, 'scroll', c('MT'))
  brm_model <- fit_brm_model(dat_prepared, formula7)
  save_model(brm_model, MODEL_FOLDER, model_name)
}

main()
