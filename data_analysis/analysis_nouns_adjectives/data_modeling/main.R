source(file.path(scripts_folder, 'data_preparation.R'))
source(file.path(scripts_folder, 'models.R'))


scripts_folder <- './analysis_nouns_adjectives/data_modeling'
nouns_adjectives_data <- 'nouns_adjectives.csv'


main <- function() {
  
  dat <- read.csv(file.path('../data', 'nouns_adjectives.csv'), sep = '\t')
  dat_prepared <- prepare_data_pipeline(dat, 'scroll', c('MT'))
  print(dim(dat_prepared))
}

main()
