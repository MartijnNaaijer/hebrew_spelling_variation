library(tidyverse)
library(brms)
library(bayesplot)
library(tidybayes)
library(ggeffects)

DATASET<- 'nouns_adjectives.csv'
dat <- read.csv(file.path('../data', DATASET), sep = '\t')
dat <- dat %>% filter(scroll == 'MT') 
dat$book2 <- dat$book %>% str_replace_all('1_', '') %>% str_replace_all('2_', '')
mt_books <- unique(dat$book2)
mt_books

formula7 <- has_vowel_letter ~ 
  has_pronominal_suffix*type*law_phase + 
  has_nme*type*law_phase + 
  has_prefix*type*law_phase + 
  (has_pronominal_suffix*type + has_nme*type + has_prefix*type | book2/lex_type)

MODEL_FOLDER <- './analysis_nouns_adjectives/output/models'
MODEL_NAME <- 'bayes_model_mt_var7.rds'

file_path_mt_var <- file.path(MODEL_FOLDER, MODEL_NAME)
mt_var_model <- readRDS(file_path_mt_var)

coef <- fixef(mt_var_model, summary = TRUE)
coef

coef_ran <- ranef(mt_var_model, summary = TRUE)
coef_ran

model_vars <- get_variables(mt_var_model)
model_vars

color_scheme_set("red")
ppc_dens_overlay(y = mt_var_model$y,
                 yrep = posterior_predict(mt_var_model, draws = 50))

# make plots to check for convergence
plot(mt_var_model)

plot(conditional_effects(mt_var_model, effects = 'has_pronominal_suffix'))
plot(conditional_effects(mt_var_model, effects = 'has_nme'))
plot(conditional_effects(mt_var_model, effects = 'has_prefix'))
plot(conditional_effects(mt_var_model, effects = 'law_phase'))

# does not work
# ggpredict(mt_var_model, terms = c("type [last]", 'has_nme')) |> plot()

# Extract random effect: book
mt_draws_random_book <- mt_var_model %>%
  spread_draws(r_book2[book,term])

dim(mt_draws_random_book)
head(mt_draws_random_book)

data_wide <- spread(mt_draws_random_book, term, r_book2)
data_wide$book <- factor(data_wide$book, levels=mt_books)
colnames(data_wide)

# Last syllable
intercept_last <- data_wide |>
  median_qi(condition_mean = Intercept, .width = c(.95, .66))

# Last with prefix
prefix_effect_last <- data_wide |>
  median_qi(condition_mean = Intercept + has_prefix1, .width = c(.95, .66))

intercept_last %>% 
  ggplot(aes(y = book, x = condition_mean, xmin = .lower, xmax = .upper)) +
  geom_pointinterval() +
  ggtitle('Random effect: book and last syllable intercept')

prefix_effect_last %>% 
  ggplot(aes(y = book, x = condition_mean, xmin = .lower, xmax = .upper)) +
  geom_pointinterval() +
  ggtitle('Random effect: book and last syllable with prefix')

# Last with nme
nme_effect_last <- data_wide |>
  median_qi(condition_mean = has_nme1, .width = c(.95, .66))

nme_effect_last %>% 
  ggplot(aes(y = book, x = condition_mean, xmin = .lower, xmax = .upper)) +
  geom_pointinterval() +
  ggtitle('Random effect: book and last syllable with nme')

# Last with prs
prs_effect_last <- data_wide |>
  median_qi(condition_mean = Intercept + has_pronominal_suffix1, .width = c(.95, .66))

prs_effect_last %>% 
  ggplot(aes(y = book, x = condition_mean, xmin = .lower, xmax = .upper)) +
  geom_pointinterval() +
  ggtitle('Random effect: book and last syllable with prs')

prs_effect_last
prs_effect_last$book2 <- prs_effect_last$book |> str_c('_with_prs')
intercept_last$book2 <- intercept_last$book
prs_last_df <- rbind(prs_effect_last, intercept_last)
prs_last_df
prs_last_df %>% 
  ggplot(aes(y = book2, x = condition_mean, xmin = .lower, xmax = .upper)) +
  geom_pointinterval() +
  ggtitle('Random effect: book and last syllable with prs')

# First syllable
intercept_first <- data_wide |>
  median_qi(condition_mean = Intercept + typefirst, .width = c(.95, .66))

prefix_effect_first <- data_wide |>
  median_qi(condition_mean = Intercept + typefirst + has_prefix1 + `typefirst:has_prefix1`, .width = c(.95, .66))


intercept_first %>% 
  ggplot(aes(y = book, x = condition_mean, xmin = .lower, xmax = .upper)) +
  geom_pointinterval() +
  ggtitle('Random effect: book and first syllable intercept')

prefix_effect_first %>% 
  ggplot(aes(y = book, x = condition_mean, xmin = .lower, xmax = .upper)) +
  geom_pointinterval() +
  ggtitle('Random effect: book and first syllable with prefix')

