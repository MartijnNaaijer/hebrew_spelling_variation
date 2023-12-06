source(file.path('./analysis_nouns_adjectives/data_modeling', 'data_preparation.R'))
#source(file.path(scripts_folder, 'models.R'))


DATASET<- 'nouns_adjectives.csv'
MODEL_FOLDER <- './analysis_nouns_adjectives/output/models'
MODEL_NAME <- 'bayes_model_mt_var7.rds'

main <- function() {
  
  dat <- read.csv(file.path('../data', DATASET), sep = '\t')
  print(table(dat$scroll))
  dat_prepared <- prepare_data_pipeline(dat, 'scroll', 'NO')
  #brm_model <- fit_brm_model(dat_prepared, formula7)
  #save_model(brm_model, MODEL_FOLDER, model_name)
  print(dim(dat_prepared))
  
  return(dat_prepared)
}

dat <- main()
dim(dat)
str(dat)
table(dat$scr_book2)
