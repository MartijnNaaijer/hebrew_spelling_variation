library(tidyverse)
library(brms)
library(bayesplot)
library(tidybayes)
library(ggeffects)

MODEL_FOLDER <- './analysis_nouns_adjectives/output/models'
MODEL <- 'bayes_model_mt_var7.rds'

file_path_mt_var <- file.path(MODEL_FOLDER, MODEL)
mt_var_model <- readRDS(file_path_mt_var)

coef <- fixef(mt_var_model, summary = TRUE)
coef

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
