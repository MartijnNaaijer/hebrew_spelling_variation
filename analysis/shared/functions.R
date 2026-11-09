################################################################################
# functions.R (analysis_verbs)
# Merge of ../functions.R (original helpers) and ../functions_cleaned.R.
# Source AFTER config.R (fit_or_load() uses MODEL_FOLDER).
################################################################################

library(tidyverse)
library(brms)
library(bayesplot)
library(tidybayes)
library(bayestestR)
library(binom)

fit_brm_model <- function(data, 
                          formula, 
                          warmup, 
                          iter, 
                          adapt_delta, 
                          prior_intercept_log, 
                          has_no_fixed_vars,
                          max_treedepth = 10) {
  
  stanvars <- stanvar(prior_intercept_log, name='prior_intercept_log')
  
  if (missing(has_no_fixed_vars)) {

  infaprior <- prior(normal(prior_intercept_log, 5), class = "Intercept") +
    prior(normal(0, 5), class = "b")

  } else {

    infaprior <- prior(normal(prior_intercept_log, 5), class = "Intercept")
  }
  
  trace <- brm(formula = formula,
               prior = infaprior,
               data = data,
               family = bernoulli(link = "logit"),
               warmup = warmup,
               iter = iter,
               chains = 4,
               cores = 4,
               control = list(adapt_delta = adapt_delta,
                              max_treedepth = max_treedepth),
               save_pars = save_pars(all = TRUE),
               stanvars=stanvars,
               seed = 123)
  
  return(trace)
}


logit2prob <- function(logit){
  odds <- exp(logit)
  prob <- odds / (1 + odds)
  return(prob)
}

prob2logit <- function(prob) {
  logit <- log(prob / (1 - prob))
  return(logit)
}

logit2odds <- function(logit){
  odds <- exp(logit)
  return(odds)
}

##############################################################

# READ DATA

import_bib_data <- function(data_folder, data_file) {
  file_path <- file.path(data_folder, data_file)
  dat <- read.csv(file_path, sep='\t')
  return(dat)
}


##############################################################

# CLEAN/PREPARE DATA

remove_ketiv_qere <- function(dat) {
  dat <- dat[!(nchar(dat$pattern) == 0 & dat$scroll == 'MT'),]
  return(dat)
}


add_col_has_suffix <- function(dat) {
  dat$has_suffix <- as.factor(as.numeric(dat$has_prs | dat$has_nme | dat$has_hloc))
  return(dat)
}


make_book2_column <- function(dat) {
  dat$book2 <- dat$book %>% str_replace('1_', '') |> str_replace('2_', '')
  return(dat)
}


make_scr_book2_column <- function(dat) {
  dat$scr_book2 <- paste(dat$scroll, dat$book2, sep='_')
  
  scr_books <- unique(dat$scr_book2)
  dat$scr_book2 <- factor(dat$scr_book2, levels = scr_books)
  return(dat)
}


make_factor_columns <- function(dat, factor_columns) {
  dat[,factor_columns] <- lapply(dat[,factor_columns] , factor)
  return(dat)
}


make_law_phase_column <- function(dat, LAW_BOOKS, EBH_BOOKS, LBH_BOOKS) {
  dat$phase <- ifelse(dat$book %in% EBH_BOOKS, 'EBH', ifelse(dat$book %in% LBH_BOOKS, 'LBH', 'NO'))
  dat$law_phase <- ifelse(dat$book %in% LAW_BOOKS, 0, ifelse(dat$book %in% EBH_BOOKS, 1, 
                                                             ifelse(dat$book %in% LBH_BOOKS, 2, 3)))
  dat$law_phase <- factor(dat$law_phase, levels=c(0, 1, 2, 3)) |> droplevels()
  return(dat)
}


make_law_phase2_column <- function(dat, LAW_BOOKS, EBH_BOOKS, LBH_BOOKS, QSP_SCROLLS, law_phase2_levels) {
  dat$law_phase2 <- ifelse(dat$book %in% LAW_BOOKS, 'Pentateuch',
                           ifelse(dat$book %in% EBH_BOOKS, 'Former Prophets', 
                                  ifelse(dat$book %in% LBH_BOOKS, 'LBH', 
                                         'Other')))
  
  dat$law_phase2 <- ifelse(!dat$scroll %in% c(c('MT', 'SP'), QSP_SCROLLS), paste0('Non-QSP ', dat$law_phase2),
                           ifelse(dat$scroll %in% QSP_SCROLLS, paste0('QSP ', dat$law_phase2), 
                                  ifelse(dat$scroll == 'SP', 'SP', 
                                         paste0('MT ', dat$law_phase2))))
  
  dat$law_phase2 <- factor(dat$law_phase2, levels=law_phase2_levels) |> droplevels()
  return(dat)
}

make_law_phase3_column <- function(dat, QSP_SCROLLS, law_phase3_levels) {
  # law_phase3 contains only value "QSP" for QSP scrolls
  dat$law_phase3 <- ifelse(dat$scroll %in% QSP_SCROLLS, 'QSP', as.character(dat$law_phase2))
  dat$law_phase3 <- factor(dat$law_phase3, levels=law_phase3_levels) |> droplevels()
  return(dat)
}


split_isaiah_scroll <- function(dat) {
  dat$scroll <- ifelse(dat$scroll == '1Qisaa' & dat$chapter < 34, '1QisaaI', 
                       ifelse(dat$scroll == '1Qisaa' & dat$chapter > 33, '1QisaaII', 
                              dat$scroll))
  return(dat)
}

##################################################################################

# Visualize data

make_plot_groups_of_books <- function(dataset) {
  
  fullness_df <- dataset |> group_by(law_phase2) |> summarise(full_count = sum(as.numeric(as.character(has_vowel_letter))),
                                                              total_count = n())
  
  hpd_fullness <- binom.bayes(
    x = fullness_df$full_count, n = fullness_df$total_count, type = "highest", 
    conf.level = 0.95, tol = 1e-9)
  hpd_fullness$law_phase2 <- fullness_df$law_phase2
  
  ggplot(hpd_fullness) +
    geom_bar( aes(x=law_phase2, y=mean), stat="identity", fill='skyblue', alpha=0.7) +
    geom_errorbar( aes(x=law_phase2, ymin=lower, ymax=upper), width=0.4, colour='black', alpha=0.9, size=1.3) + 
    ylab('Fraction with full spelling') +
    xlab('') +
    theme(axis.text.x = element_text(angle = 45, hjust=1, size=16))
  
}

make_groups_suffix_plot <- function(dataset) {
  ay_ay_df <- dataset |> group_by(law_phase2, has_suffix) |> summarise(full_count = sum(as.numeric(as.character(has_vowel_letter))),
                                                                       total_count = n())
  
  hpd_ay_ay <- binom.bayes(
    x = ay_ay_df$full_count, n = ay_ay_df$total_count, type = "highest", conf.level = 0.95, tol = 1e-9)
  hpd_ay_ay$law_phase2 <- ay_ay_df$law_phase2
  hpd_ay_ay$has_suffix <- ay_ay_df$has_suffix
  
  ggplot(data = hpd_ay_ay, aes(x = law_phase2, y = mean, fill = as.factor(has_suffix))) +
    geom_bar(stat = "identity", color = "black", position = position_dodge()) +
    labs(x = '', y = 'Fraction with full spelling') +
    geom_errorbar( aes(x=law_phase2, ymin=lower, ymax=upper), width=0.4, colour='black', alpha=0.9, size=1.3,
                   position = position_dodge(0.9)) + 
    theme_minimal() +
    theme(text = element_text(size = 20)) +
    theme(axis.text.x = element_text(angle = 45, hjust=1)) +
    scale_fill_discrete(name = '', labels = c('Without suffix', 'With suffix'))
}
  
  make_groups_prefix_plot <- function(dataset) {
    ay_ay_df <- dataset |> group_by(law_phase2, has_prefix) |> summarise(full_count = sum(as.numeric(as.character(has_vowel_letter))),
                                                                         total_count = n())
    
    hpd_ay_ay <- binom.bayes(
      x = ay_ay_df$full_count, n = ay_ay_df$total_count, type = "highest", conf.level = 0.95, tol = 1e-9)
    hpd_ay_ay$law_phase2 <- ay_ay_df$law_phase2
    hpd_ay_ay$has_prefix <- ay_ay_df$has_prefix
    
    ggplot(data = hpd_ay_ay, aes(x = law_phase2, y = mean, fill = as.factor(has_prefix))) +
      geom_bar(stat = "identity", color = "black", position = position_dodge()) +
      labs(x = '', y = 'Fraction with full spelling') +
      geom_errorbar( aes(x=law_phase2, ymin=lower, ymax=upper), width=0.4, colour='black', alpha=0.9, size=1.3,
                     position = position_dodge(0.9)) + 
      theme_minimal() +
      theme(text = element_text(size = 20)) +
      theme(axis.text.x = element_text(angle = 45, hjust=1)) +
      scale_fill_discrete(name = '', labels = c('Without prefix', 'With prefix'))
}



##############################################################
# MODELLING
##############################################################

# Fit a Bayesian logistic model with fit_brm_model(), or read it from
# MODEL_FOLDER/<file_name> if it was fitted before. Set refit = TRUE to force
# a new fit (the stored file is then overwritten).
fit_or_load <- function(file_name,
                        data,
                        formula,
                        prior_intercept_logit,
                        warmup = 4000,
                        iter = 8000,
                        adapt_delta = 0.99,
                        has_no_fixed_vars = FALSE,
                        max_treedepth = 10,
                        refit = FALSE) {

  file_path <- file.path(MODEL_FOLDER, file_name)

  if (file.exists(file_path) && !refit) {
    message('Loading stored model: ', file_path)
    model <- readRDS(file_path)
    # A stored fit made on an older version of the dataset is not comparable
    # with the current data (nor with other models via Bayes factors).
    if (!is.null(data) && nrow(model$data) != nrow(data)) {
      warning('Stored model ', file_name, ' was fitted on ', nrow(model$data),
              ' rows, current data has ', nrow(data),
              ' rows. Consider refit = TRUE.', call. = FALSE)
    }
    return(model)
  }

  check_allow_fit(paste('Model', file_name))
  message('Fitting model: ', file_name)
  if (has_no_fixed_vars) {
    model <- fit_brm_model(data, formula, warmup, iter, adapt_delta,
                           prior_intercept_logit, TRUE,
                           max_treedepth = max_treedepth)
  } else {
    model <- fit_brm_model(data, formula, warmup, iter, adapt_delta,
                           prior_intercept_logit,
                           max_treedepth = max_treedepth)
  }

  saveRDS(model, file = file_path)
  return(model)
}


# Compute Bayes factors (bridge sampling) for pairs of models.
# models: named list of brmsfit objects
# pairs:  list of length-2 character vectors, c('model_a', 'model_b');
#         BF > 1 favours model_a.
bayes_factor_table <- function(models, pairs) {
  map_dfr(pairs, function(p) {
    bf <- bayes_factor(models[[p[1]]], models[[p[2]]], silent = TRUE)
    tibble(model_a = p[1], model_b = p[2], bf_a_over_b = bf$bf)
  })
}


##############################################################
# EXPLORATION
##############################################################

# Bar plot of the fraction of full spellings (with 95% HPD interval, Bayesian
# binomial) per level of group_var. With fill_var, bars are split (dodged) by
# a second variable, e.g. has_suffix, has_prefix, ay_ay, iii_h.
plot_fullness_by_group <- function(dataset,
                                   group_var = 'law_phase2',
                                   fill_var = NULL,
                                   fill_labels = NULL,
                                   legend_title = '') {

  group_vars <- c(group_var, fill_var)

  counts <- dataset |>
    group_by(across(all_of(group_vars))) |>
    summarise(full_count = sum(as.numeric(as.character(has_vowel_letter))),
              total_count = n(),
              .groups = 'drop')

  hpd <- binom.bayes(x = counts$full_count, n = counts$total_count,
                     type = 'highest', conf.level = 0.95, tol = 1e-9)
  hpd <- bind_cols(counts, hpd[, c('mean', 'lower', 'upper')])

  if (is.null(fill_var)) {
    p <- ggplot(hpd, aes(x = .data[[group_var]], y = mean)) +
      geom_bar(stat = 'identity', fill = 'skyblue', alpha = 0.7) +
      geom_errorbar(aes(ymin = lower, ymax = upper),
                    width = 0.4, colour = 'black', alpha = 0.9, linewidth = 1.3)
  } else {
    fill_scale <- if (is.null(fill_labels)) {
      scale_fill_discrete(name = legend_title)
    } else {
      scale_fill_discrete(name = legend_title, labels = fill_labels)
    }
    p <- ggplot(hpd, aes(x = .data[[group_var]], y = mean,
                         fill = as.factor(.data[[fill_var]]))) +
      geom_bar(stat = 'identity', color = 'black', position = position_dodge()) +
      geom_errorbar(aes(ymin = lower, ymax = upper),
                    width = 0.4, colour = 'black', alpha = 0.9, linewidth = 1.3,
                    position = position_dodge(0.9)) +
      fill_scale
  }

  p +
    labs(x = '', y = 'Fraction with full spelling') +
    theme_minimal() +
    theme(text = element_text(size = 20),
          axis.text.x = element_text(angle = 45, hjust = 1))
}


##############################################################
# VISUALISATION OF MODEL RESULTS
##############################################################

# Posterior mean and HDI (95% and 66%) of linear combinations of coefficients,
# on the logit scale.
# combos: named list; each element is a character vector of parameter names
#         that are summed, e.g.
#         list('Intercept'           = 'b_Intercept',
#              'Verbs with a suffix' = c('b_Intercept', 'b_has_suffix1'))
# The factor levels of `key` follow the reversed order of `combos`, so the first
# combination is plotted at the top.
summarise_posterior_combinations <- function(model, combos) {
  draws <- as_draws_df(model)

  missing_pars <- setdiff(unique(unlist(combos)), names(draws))
  if (length(missing_pars) > 0) {
    stop('Parameters not in model: ', paste(missing_pars, collapse = ', '))
  }

  sums <- map_dfc(combos, function(pars) rowSums(as.data.frame(draws)[, pars, drop = FALSE]))

  sums |>
    pivot_longer(everything(), names_to = 'key') |>
    group_by(key) |>
    mean_hdi(value, .width = c(.95, .66)) |>
    mutate(key = factor(key, levels = rev(names(combos))))
}


plot_posterior_summary <- function(summary_df, x_limits = NULL, x_label = '') {
  p <- summary_df |>
    ggplot(aes(y = key, x = value, xmin = .lower, xmax = .upper)) +
    geom_pointinterval() +
    xlab(x_label) +
    ylab('')
  if (!is.null(x_limits)) p <- p + xlim(x_limits[1], x_limits[2])
  p
}


# Table of fixed effects with probability of direction (pd), saved as an image.
make_fixed_effects_table <- function(model, file_path = NULL) {
  fixed <- summary(model)$fixed
  fixed$Rhat <- sprintf('%.2f', fixed$Rhat)
  for (name in c('Estimate', 'Est.Error', 'l-95% CI', 'u-95% CI')) {
    fixed[, name] <- round(fixed[, name], 2)
  }
  fixed$Bulk_ESS <- round(fixed$Bulk_ESS, 0)
  fixed$Tail_ESS <- round(fixed$Tail_ESS, 0)

  p_dir <- p_direction(model, effects = 'fixed') |> as.data.frame()
  fixed$pd <- round(p_dir$pd[match(paste0('b_', rownames(fixed)), p_dir$Parameter)], 2)

  if (!is.null(file_path)) {
    fixed |>
      htmlTable::htmlTable() |>
      kableExtra::save_kable(file = file_path)
  }
  fixed
}


# Sorted random intercepts (posterior mean with 95% CI) of one grouping factor.
# pattern: optional regular expression to select levels, e.g. 'MT_Genesis' or 'BRK'.
plot_random_intercepts <- function(model, group, pattern = NULL, text_size = 7) {
  re <- ranef(model)[[group]][, , 'Intercept'] |> as.data.frame()
  if (!is.null(pattern)) re <- re[grepl(pattern, rownames(re)), , drop = FALSE]
  re <- re[order(re$Estimate), ]
  re$level <- factor(rownames(re), levels = rownames(re))

  re |>
    ggplot(aes(y = level, x = Estimate, xmin = Q2.5, xmax = Q97.5)) +
    geom_pointinterval() +
    theme(axis.text.y = element_text(size = text_size),
          axis.title.y = element_blank())
}


##############################################################
# MODEL VERIFICATION
##############################################################

# Standard checks for a fitted Bernoulli brms model:
#   1. convergence: max Rhat, min effective sample size ratio, divergences
#   2. trace plots and posterior densities of the fixed effects
#   3. posterior predictive check (observed vs predicted proportion of full spellings)
#   4. LOO (Pareto k diagnostics) and Bayesian R2
#   5. classification accuracy, sensitivity and specificity
# If image_folder and prefix are given, the plots are saved there.
# Returns a list with the numeric results.
verify_model <- function(model, image_folder = NULL, prefix = NULL,
                         outcome = 'has_vowel_letter') {

  save <- !is.null(image_folder) && !is.null(prefix)
  save_plot <- function(p, name) {
    if (save) ggsave(file.path(image_folder, paste0(prefix, '_', name, '.png')), p)
    print(p)
  }

  # 1. Convergence
  draws_summary <- posterior::summarise_draws(as_draws_df(model), 'rhat', 'ess_bulk')
  rhats <- draws_summary$rhat
  neff <- draws_summary$ess_bulk / ndraws(model)
  n_divergent <- nuts_params(model) |>
    filter(Parameter == 'divergent__') |>
    pull(Value) |>
    sum()
  cat('Max Rhat:              ', round(max(rhats, na.rm = TRUE), 3), '(should be < 1.01)\n')
  cat('Min bulk ESS / draws:  ', round(min(neff, na.rm = TRUE), 3), '(should be > 0.1)\n')
  cat('Divergent transitions: ', n_divergent, '(should be 0)\n')

  # 2. Trace and density plots of fixed effects
  save_plot(mcmc_plot(model, type = 'trace', variable = '^b_', regex = TRUE), 'trace')
  save_plot(mcmc_plot(model, type = 'dens', variable = '^b_', regex = TRUE), 'dens')

  # 3. Posterior predictive check
  save_plot(pp_check(model, type = 'stat', stat = 'mean', ndraws = 1000), 'ppcheck_mean')
  save_plot(pp_check(model, type = 'bars', ndraws = 200), 'ppcheck_bars')

  # 4. LOO and R2
  model_loo <- loo(model)
  print(model_loo)
  pareto_k <- model_loo$diagnostics$pareto_k
  cat('Share of Pareto k > 0.7:', round(mean(pareto_k > 0.7), 4), '\n')
  r2 <- bayes_R2(model)
  print(r2)

  # 5. Classification
  observed <- as.numeric(as.character(model$data[[outcome]]))
  predicted <- as.numeric(fitted(model)[, 'Estimate'] > 0.5)
  accuracy <- mean(predicted == observed)
  sensitivity <- mean(predicted[observed == 1] == 1)
  specificity <- mean(predicted[observed == 0] == 0)
  cat('Accuracy:   ', round(accuracy, 3), '\n')
  cat('Sensitivity:', round(sensitivity, 3), '\n')
  cat('Specificity:', round(specificity, 3), '\n')

  invisible(list(max_rhat = max(rhats, na.rm = TRUE),
                 min_neff_ratio = min(neff, na.rm = TRUE),
                 n_divergent = n_divergent,
                 loo = model_loo,
                 share_pareto_k_bad = mean(pareto_k > 0.7),
                 bayes_r2 = r2,
                 accuracy = accuracy,
                 sensitivity = sensitivity,
                 specificity = specificity))
}


################################################################################
# ANALYSIS_VERBS: MODELLING WITH EXPLICIT PRIORS (added 2026-10-08)
#
#   - book_priors()        weakly informative priors on the logit scale
#   - fit_model()          fit a nested Bernoulli brms model once, reload afterwards
#   - kfold_cached()       grouped k-fold cross-validation, cached on disk
#   - bridge_cached()      log marginal likelihood (bridge sampling), cached
#   - bf_cached()          Bayes factor from two cached bridge sampling results
#   - group_ppc()          posterior predictive check per group
################################################################################

# Weakly informative priors (logit scale): normal(0, scale_b) for coefficients
# and intercept, exponential(1) for the standard deviations of the random
# intercepts. normal(0, 1.5) keeps probabilities between ~5% and ~95% a priori
# for a single coefficient instead of piling prior mass near 0 and 1.
book_priors <- function(scale_b = 1.5, has_fixed = TRUE) {
  p <- set_prior(paste0('normal(0, ', scale_b, ')'), class = 'Intercept') +
    set_prior('exponential(1)', class = 'sd')
  if (has_fixed) p <- p + set_prior(paste0('normal(0, ', scale_b, ')'), class = 'b')
  p
}


# Fitting switch: set options(analysis_verbs.allow_fit = FALSE) (ALLOW_FIT in
# the scripts) to make sure nothing is fitted; stored results are still loaded.
check_allow_fit <- function(what) {
  if (!isTRUE(getOption('analysis_verbs.allow_fit', TRUE))) {
    stop(what, ' is not stored yet and fitting is switched off ',
         '(ALLOW_FIT = FALSE). Set ALLOW_FIT <- TRUE to fit it.', call. = FALSE)
  }
}


# Fit a Bernoulli (logit) model with the given priors, or read it from
# MODEL_FOLDER/<file_name>. save_pars(all = TRUE) is needed for bridge sampling.
# sample_prior = 'only' gives a prior predictive model.
# Sampler: warmup 1000, iter 3000 (8000 draws) for all fits from 2026-10-17
# (author; converged well in ptca). Fits stored before that used 2000/6000;
# kfold() refits a stored model with that model's own settings.
fit_model <- function(file_name, formula, data, priors,
                      warmup = 1000, iter = 3000, adapt_delta = 0.99,
                      sample_prior = 'no', refit = FALSE) {
  file_path <- file.path(MODEL_FOLDER, file_name)
  if (file.exists(file_path) && !refit) {
    model <- readRDS(file_path)
    if (nrow(model$data) != nrow(data)) {
      warning('Stored model ', file_name, ' was fitted on ', nrow(model$data),
              ' rows, current data has ', nrow(data), ' rows. Consider refit = TRUE.',
              call. = FALSE)
    }
    return(model)
  }
  check_allow_fit(paste('Model', file_name))
  message('Fitting model: ', file_name)
  model <- brm(formula = formula,
               data = data,
               family = bernoulli(link = 'logit'),
               prior = priors,
               sample_prior = sample_prior,
               warmup = warmup,
               iter = iter,
               chains = 4,
               cores = 4,
               control = list(adapt_delta = adapt_delta),
               save_pars = save_pars(all = TRUE),
               seed = 123)
  saveRDS(model, file_path)
  model
}


# Grouped k-fold cross-validation (whole groups left out per fold), cached as
# MODEL_FOLDER/kfold_<file_stem>.rds. Pass the same `folds` vector to all models
# that are compared. Folds are refitted one after another (each refit uses 4
# cores for its chains; parallel folds would copy the large fitted model to
# every worker).
kfold_cached <- function(model, file_stem, folds, refit = FALSE) {
  file_path <- file.path(MODEL_FOLDER, paste0('kfold_', file_stem, '.rds'))
  if (file.exists(file_path) && !refit) return(readRDS(file_path))
  check_allow_fit(paste('k-fold result', file_stem))
  message('k-fold cross-validation: ', file_stem)
  # brms runs the folds through `future` even sequentially; its size check on
  # the (large) fitted model is not needed when nothing is sent to workers.
  old_opt <- options(future.globals.maxSize = Inf)
  on.exit(options(old_opt), add = TRUE)
  future::plan(future::sequential)
  kf <- kfold(model, folds = folds, K = length(unique(folds)))
  saveRDS(kf, file_path)
  kf
}


# Log marginal likelihood by bridge sampling (5 repetitions, to show the
# estimation error), cached as MODEL_FOLDER/bridge_<name>.rds.
bridge_cached <- function(model, name, refit = FALSE) {
  file_path <- file.path(MODEL_FOLDER, paste0('bridge_', name, '.rds'))
  if (file.exists(file_path) && !refit) return(readRDS(file_path))
  check_allow_fit(paste('Bridge sampling result', name))
  message('Bridge sampling: ', name)
  bridge <- bridge_sampler(model, repetitions = 5, silent = TRUE)
  saveRDS(bridge, file_path)
  bridge
}

# Bayes factor of model_a over model_b from cached bridge sampling results.
# bf: based on the median log marginal likelihoods; bf_min / bf_max: range over
# all combinations of the repetitions (estimation uncertainty).
bf_cached <- function(model_a, model_b, name_a, name_b) {
  logml_a <- bridge_cached(model_a, name_a)$logml
  logml_b <- bridge_cached(model_b, name_b)$logml
  diffs <- outer(logml_a, logml_b, '-')
  tibble(comparison = paste(name_a, 'vs', name_b),
         bf = exp(median(logml_a) - median(logml_b)),
         bf_min = exp(min(diffs)),
         bf_max = exp(max(diffs)))
}


# Observed vs predicted share of full spellings per group: for each posterior
# draw the share of full spellings predicted (posterior_predict) per level of
# group_var. Returns observed share, n and 50% / 95% predictive intervals.
group_ppc <- function(model, data, group_var, ndraws = 4000) {
  yrep <- posterior_predict(model, ndraws = ndraws)
  groups <- data[[group_var]]
  y <- as.numeric(as.character(data$has_vowel_letter))
  map_dfr(levels(factor(groups)), function(g) {
    idx <- which(groups == g)
    pred <- rowMeans(yrep[, idx, drop = FALSE])
    tibble(group = g, n = length(idx), observed = mean(y[idx]),
           pred_mean = mean(pred),
           l95 = quantile(pred, 0.025), u95 = quantile(pred, 0.975),
           l50 = quantile(pred, 0.25), u50 = quantile(pred, 0.75))
  }) |>
    mutate(group = factor(group, levels = levels(factor(groups))))
}


################################################################################
# FIGURES FOR THE BOOK
#
# Static figures for print: one light theme, recessive grid, text in ink
# colours, at most three categorical hues (validated reference palette slots
# 1-3: blue, orange, aqua), grey for secondary marks. Hebrew labels need the
# ragg (PNG) and cairo (PDF) devices.
#
# Font: Charis, the body font of the book (SIL Open Font License; files and
# licence in analysis_verbs/fonts/, installed for the Windows user on
# 2026-10-19 so that cairo_pdf finds it too). Hebrew in labels: heb_md() sets
# it in SBL Hebrew; the plot then needs markdown_y() (or the ggtext element
# for the strip or legend), which renders the label as markdown (ggtext).
################################################################################

BOOK_FONT <- 'Charis'
local({
  font_dir <- if (exists('ANALYSIS_DIR')) file.path(ANALYSIS_DIR, 'fonts') else 'fonts'
  if (!BOOK_FONT %in% systemfonts::system_fonts()$family &&
      file.exists(file.path(font_dir, 'Charis-Regular.ttf'))) {
    # Not installed: register the files for ragg (PNG); PDF falls back.
    systemfonts::register_font(BOOK_FONT,
      plain = file.path(font_dir, 'Charis-Regular.ttf'),
      bold = file.path(font_dir, 'Charis-Bold.ttf'),
      italic = file.path(font_dir, 'Charis-Italic.ttf'),
      bolditalic = file.path(font_dir, 'Charis-BoldItalic.ttf'))
  }
})

# Screen devices: the windows() device needs the families mapped; under
# Rscript the default pdf() device does not know Charis ("invalid font type"
# when a plot is printed), so printed plots go to a temporary PNG instead.
# The saved figures (save_book_figure) are not affected.
if (.Platform$OS.type == 'windows') {
  grDevices::windowsFonts(Charis = grDevices::windowsFont('Charis'),
                          `SBL Hebrew` = grDevices::windowsFont('SBL Hebrew'))
}
if (!interactive()) {
  options(device = function(...) ragg::agg_png(tempfile(fileext = '.png'), ...))
}

# Hebrew text for a markdown label, in SBL Hebrew. The family name is quoted
# because gridtext cuts an unquoted name at the space; the left-to-right marks
# keep the word order of mixed Hebrew/English labels.
heb_md <- function(x) {
  paste0("<span style=\"font-family:'SBL Hebrew'\">\u200e", x, "\u200e</span>")
}

# Hebrew letters of an ETCBC lexeme ('KTB[' -> 'כתב'), with final forms; F
# (sin) and C (shin) both become ש. Use with heb_md() in labels.
etcbc_to_hebrew <- function(x) {
  map <- c('>' = 'א', B = 'ב', G = 'ג', D = 'ד', H = 'ה', W = 'ו', Z = 'ז', X = 'ח',
           V = 'ט', J = 'י', K = 'כ', L = 'ל', M = 'מ', N = 'נ', S = 'ס', '<' = 'ע',
           P = 'פ', Y = 'צ', Q = 'ק', R = 'ר', F = 'ש', C = 'ש', T = 'ת')
  final <- c('כ' = 'ך', 'מ' = 'ם', 'נ' = 'ן', 'פ' = 'ף', 'צ' = 'ץ')
  vapply(gsub('[^A-Z<>]', '', x), function(w) {
    letters <- unname(map[strsplit(w, '')[[1]]])
    n <- length(letters)
    if (letters[n] %in% names(final)) letters[n] <- final[[letters[n]]]
    paste(letters, collapse = '')
  }, character(1), USE.NAMES = FALSE)
}

# Plain text of heb_md() labels, for CSV tables (drops the markup and the
# left-to-right marks). Works on character and factor columns.
strip_md <- function(x) {
  out <- gsub('<[^>]+>|\u200e', '', as.character(x))
  if (is.factor(x)) factor(out, levels = unique(gsub('<[^>]+>|\u200e', '', levels(x)))) else out
}
md_to_csv <- function(tab) mutate(tab, across(where(\(v) is.character(v) || is.factor(v)), strip_md))

# Render the y-axis labels as markdown (needed for heb_md()). With ggplot2 4.0
# the element must be set on axis.text.y.left, not axis.text.y.
markdown_y <- function() {
  theme(axis.text.y.left = ggtext::element_markdown(colour = BOOK_INK_2))
}
# The same for the legend and the note (caption) of a plot.
markdown_legend <- function() theme(legend.text = ggtext::element_markdown(colour = BOOK_INK))
markdown_caption <- function() {
  theme(plot.caption = ggtext::element_markdown(colour = BOOK_INK_2, hjust = 0))
}

BOOK_INK       <- '#0b0b0b'
BOOK_INK_2     <- '#52514e'
BOOK_GRID      <- '#e5e4e0'
BOOK_BLUE      <- '#2a78d6'
BOOK_ORANGE    <- '#eb6834'
BOOK_AQUA      <- '#1baf7a'
BOOK_GREY      <- '#9c9b96'
BOOK_CATEGORICAL <- c(BOOK_BLUE, BOOK_ORANGE, BOOK_AQUA)

theme_book <- function(base_size = 11, base_family = BOOK_FONT) {
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(text = element_text(colour = BOOK_INK),
          axis.text = element_text(colour = BOOK_INK_2),
          axis.title = element_text(colour = BOOK_INK_2),
          panel.grid.major = element_line(colour = BOOK_GRID, linewidth = 0.3),
          panel.grid.minor = element_blank(),
          plot.title = element_text(face = 'bold', size = base_size + 1),
          plot.title.position = 'plot',
          plot.subtitle = element_text(colour = BOOK_INK_2),
          plot.caption = element_text(colour = BOOK_INK_2, hjust = 0),
          strip.text = element_text(colour = BOOK_INK, face = 'bold', hjust = 0),
          legend.position = 'top',
          legend.justification = 'left',
          legend.title = element_blank())
}

# Save a figure as PNG (600 dpi) and PDF; width and height in cm.
save_book_figure <- function(plot, name, width = 16, height = 10, folder = IMAGE_FOLDER) {
  ggsave(file.path(folder, paste0(name, '.png')), plot, width = width, height = height,
         units = 'cm', dpi = 600, device = ragg::agg_png, bg = 'white')
  ggsave(file.path(folder, paste0(name, '.pdf')), plot, width = width, height = height,
         units = 'cm', device = cairo_pdf)
  invisible(plot)
}

# Share of full spellings per group with 95% HPD interval (Bayesian binomial,
# Jeffreys prior) and the number of forms as label.
fullness_by_group <- function(dataset, group_var) {
  dataset |>
    group_by(group = .data[[group_var]]) |>
    summarise(full = sum(as.numeric(as.character(has_vowel_letter))),
              n = n(), .groups = 'drop') |>
    mutate(binom.bayes(full, n, type = 'highest', conf.level = 0.95,
                       tol = 1e-9)[, c('mean', 'lower', 'upper')])
}


################################################################################
# MEMORY-SAVING VARIANTS (added 2026-10-09)
#
# For larger datasets the fitted models are several GB in memory. These
# helpers load a stored model only when a result is not cached yet, and release
# it afterwards.
#   - load_model()        read MODEL_FOLDER/<file_name>
#   - kfold_lazy()        k-fold result, loading the model only if needed
#   - bridge_lazy()       bridge sampling result, loading the model only if needed
#   - bf_from_bridges()   Bayes factor from two cached bridge sampling results
################################################################################

load_model <- function(file_name) readRDS(file.path(MODEL_FOLDER, file_name))

kfold_lazy <- function(model_file, file_stem, folds, refit = FALSE) {
  file_path <- file.path(MODEL_FOLDER, paste0('kfold_', file_stem, '.rds'))
  if (file.exists(file_path) && !refit) return(readRDS(file_path))
  model <- load_model(model_file)
  on.exit({ rm(model); gc() }, add = TRUE)
  kfold_cached(model, file_stem, folds, refit = refit)
}

bridge_lazy <- function(model_file, name, refit = FALSE) {
  file_path <- file.path(MODEL_FOLDER, paste0('bridge_', name, '.rds'))
  if (file.exists(file_path) && !refit) return(readRDS(file_path))
  model <- load_model(model_file)
  on.exit({ rm(model); gc() }, add = TRUE)
  bridge_cached(model, name, refit = refit)
}

bf_from_bridges <- function(bridge_a, bridge_b, name_a, name_b) {
  diffs <- outer(bridge_a$logml, bridge_b$logml, '-')
  tibble(comparison = paste(name_a, 'vs', name_b),
         bf = exp(median(bridge_a$logml) - median(bridge_b$logml)),
         bf_min = exp(min(diffs)),
         bf_max = exp(max(diffs)))
}


################################################################################
# SHARES AND PREDICTIVE CHECKS FOR BOOK FIGURES (added 2026-10-09)
#
# Moved here from infc_qal_triliteral/analysis.R (which still has identical
# local copies) so that other verb forms can use them.
#   - shares_by()    share of full spellings (95% HPD) per combination of groups
#   - plot_shares()  dot-and-interval figure of shares_by() output (column 'row')
#   - plot_ppc()     figure of group_ppc() output: observed vs predicted shares
################################################################################

shares_by <- function(dataset, ...) {
  dataset |>
    group_by(...) |>
    summarise(full = sum(as.numeric(as.character(has_vowel_letter))), n = n(),
              .groups = 'drop') |>
    mutate(binom.bayes(full, n, type = 'highest', conf.level = 0.95,
                       tol = 1e-9)[, c('mean', 'lower', 'upper')])
}

plot_shares <- function(shares, colour_var = NULL, colours = BOOK_CATEGORICAL,
                        dodge_width = 0) {
  dodge <- position_dodge(width = dodge_width)
  aes_colour <- if (is.null(colour_var)) aes() else aes(colour = .data[[colour_var]],
                                                       group = .data[[colour_var]])
  p <- ggplot(shares, aes(y = row, x = mean, xmin = lower, xmax = upper)) + aes_colour
  if (is.null(colour_var)) {
    p <- p + geom_linerange(linewidth = 0.8, colour = BOOK_BLUE, position = dodge) +
      geom_point(size = 2.3, colour = BOOK_BLUE, position = dodge)
  } else {
    p <- p + geom_linerange(linewidth = 0.8, position = dodge) +
      geom_point(size = 2.3, position = dodge) +
      scale_colour_manual(values = colours, guide = guide_legend(reverse = TRUE))
  }
  p +
    geom_text(aes(x = 1.02, label = paste0('n = ', n)), hjust = 0, size = 2.6,
              colour = BOOK_INK_2, position = dodge, show.legend = FALSE) +
    scale_x_continuous(limits = c(0, 1.17), breaks = seq(0, 1, 0.25),
                       labels = scales::percent) +
    labs(x = 'Full spelling (share of forms, 95% interval)', y = NULL) +
    theme_book()
}

plot_ppc <- function(ppc) {
  ppc |>
    mutate(group = fct_rev(group)) |>
    ggplot(aes(y = group)) +
    geom_linerange(aes(xmin = l95, xmax = u95), colour = BOOK_GREY, linewidth = 0.8) +
    geom_linerange(aes(xmin = l50, xmax = u50), colour = BOOK_GREY, linewidth = 2.2) +
    geom_point(aes(x = observed), colour = BOOK_BLUE, size = 2.5) +
    scale_x_continuous(limits = c(0, 1), labels = scales::percent) +
    labs(x = 'Share of full spellings', y = NULL,
         caption = 'Blue: observed. Grey: predicted by the model (50% and 95% interval).') +
    theme_book()
}


################################################################################
# PARALLEL PASSAGES (added 2026-10-09, session verbs-49)
#
# parallel_forms(): pairs each scroll form with the MT form of the same lexeme
# in the same verse. When a verse contains several forms of the same lexeme,
# the n-th form in the scroll is paired with the n-th form in the MT (text
# order = tf_id order); unmatched forms are dropped. Needs the columns
# book, chapter, verse, lex, scroll, tf_id, has_vowel_letter, corpus, g_cons.
################################################################################

#
# occ (added 2026-11-05): a table from raw_occurrences() (source, tf_id,
# occurrence and n_raw = number of forms of the lexeme in the verse in the raw
# text). Without it the forms are numbered within `dataset`, i.e. after the
# cleaning; then a form dropped by the cleaning (a reconstructed form, a form
# outside the feature) shifts the pairing of the later forms of the lexeme in
# the verse (1Q8 Isa 49:7 QDWC, 4Q57 Isa 22:13 >KWL). With it, a scroll whose
# raw text has as many forms of the lexeme in the verse as the MT is paired by
# the position in the raw text. When the numbers differ (a plus or minus in
# the scroll, e.g. 4Q27 Num 11:32 KL: four against three) position cannot tell
# which form is the extra one; those forms keep the numbering within `dataset`
# (column pairing = 'raw text' / 'dataset'). The output keeps the tf_id of the
# MT form (mt_tf_id).

parallel_forms <- function(dataset, occ = NULL) {
  numbered <- dataset |>
    group_by(book, chapter, verse, lex, scroll) |>
    arrange(tf_id, .by_group = TRUE) |>
    mutate(occurrence = row_number()) |>
    ungroup() |>
    mutate(.row = row_number())
  if (!is.null(occ)) {
    numbered <- numbered |>
      mutate(.key = as.numeric(as.character(tf_id)), .src = witness_source(scroll)) |>
      left_join(transmute(occ, .key = as.numeric(tf_id), .src = source, raw_occurrence = occurrence, n_raw),
                by = c('.key', '.src')) |>
      select(-.key, -.src)
    if (anyNA(numbered$raw_occurrence))
      stop('parallel_forms(): no raw occurrence for tf_id ',
           paste(head(numbered$tf_id[is.na(numbered$raw_occurrence)]), collapse = ', '))
  } else {
    numbered <- numbered |> mutate(raw_occurrence = NA_integer_, n_raw = NA_integer_)
  }
  mt_forms <- numbered |>
    filter(scroll == 'MT') |>
    select(book, chapter, verse, lex, occurrence, mt_raw_occurrence = raw_occurrence, mt_n_raw = n_raw,
           mt_tf_id = tf_id, mt_g_cons = g_cons, mt_full = has_vowel_letter)
  mt_n <- distinct(mt_forms, book, chapter, verse, lex, mt_n_raw)
  sc <- numbered |>
    filter(scroll != 'MT') |>
    left_join(mt_n, by = c('book', 'chapter', 'verse', 'lex')) |>
    mutate(pairing = if_else(!is.na(n_raw) & !is.na(mt_n_raw) & n_raw == mt_n_raw, 'raw text', 'dataset')) |>
    select(-mt_n_raw)
  bind_rows(
    sc |> filter(pairing == 'raw text') |>
      inner_join(select(mt_forms, -occurrence, -mt_n_raw),
                 by = c('book', 'chapter', 'verse', 'lex', 'raw_occurrence' = 'mt_raw_occurrence')),
    sc |> filter(pairing == 'dataset') |>
      inner_join(select(mt_forms, -mt_raw_occurrence, -mt_n_raw),
                 by = c('book', 'chapter', 'verse', 'lex', 'occurrence'))) |>
    arrange(.row) |>
    select(-.row) |>
    mutate(passage = paste(book, chapter, verse, lex),
           pattern = case_when(mt_full == 1 & has_vowel_letter == 1 ~ 'both full',
                               mt_full == 0 & has_vowel_letter == 0 ~ 'both defective',
                               mt_full == 0 & has_vowel_letter == 1 ~ 'scroll fuller',
                               TRUE ~ 'MT fuller'))
}

# raw_occurrences(): the number of each form among the forms of its lexeme in
# the verse, per witness, in the raw text (tf_id order), for parallel_forms().
# Scrolls and SP: the raw files all_dss_* / all_sp_* (reconstructed forms
# included). MT: matres_mt.csv (the whole MT), restricted to the same word
# class as the scroll file. Forms that are not in the raw text at all (lost in
# a lacuna and not reconstructed) cannot be counted. Returns source (MT, SP,
# DSS), tf_id, occurrence and n_raw (forms of the lexeme in the verse).
raw_occurrences <- function(word_class, folder = DATA_FOLDER) {
  spec <- switch(word_class,
    nominal = list(files = c('all_dss_subs_adjv.csv', 'all_sp_subs_adjv.csv'),
                   mt = \(d) filter(d, sp %in% c('subs', 'adjv'))),
    ptc_qal = list(files = c('all_dss_ptc_qal.csv', 'all_sp_ptc_qal.csv'),
                   mt = \(d) filter(d, vs == 'qal', vt %in% c('ptca', 'ptcp'))),
    infc_qal = list(files = 'all_dss_infc_qal.csv', mt = \(d) filter(d, vs == 'qal', vt == 'infc')),
    infa_qal = list(files = 'all_dss_inf_abs_qal.csv', mt = \(d) filter(d, vs == 'qal', vt == 'infa')),
    niph_hiph_pe_yod = list(files = 'all_dss_niph_hiph_pe_yod.csv',
                            mt = \(d) filter(d, vs %in% c('nif', 'hif', 'hof'))),
    stop('raw_occurrences(): unknown word class ', word_class))
  rd <- function(f) readr::read_tsv(file.path(folder, f), col_types = readr::cols(.default = 'c'),
                                    progress = FALSE) |>
    select(tf_id, scroll, book, chapter, verse, lex, sp, vs, vt) |>
    mutate(tf_id = as.numeric(tf_id) + if (startsWith(f, 'all_sp_')) 100000 else 0)
  bind_rows(map(spec$files, rd), spec$mt(rd('matres_mt.csv'))) |>
    mutate(source = witness_source(scroll)) |>
    distinct(source, tf_id, .keep_all = TRUE) |>
    arrange(tf_id) |>
    group_by(scroll, book, chapter, verse, lex) |>
    mutate(occurrence = row_number(), n_raw = n()) |>
    ungroup() |>
    select(source, tf_id, occurrence, n_raw)
}

# The all_sp_* files number SP 100000 lower than the processed files (checked
# 2026-11-05: all 33,283 SP nouns and 863 SP participles match with +100000);
# without the offset SP and MT tf_ids overlap. The key is source and tf_id.
witness_source <- function(scroll) {
  scroll <- as.character(scroll)
  dplyr::case_when(scroll == 'MT' ~ 'MT', scroll == 'SP' ~ 'SP', TRUE ~ 'DSS')
}

# The same with the MT form matched in the preprocessing (column mt_match =
# tf_id of the MT form; only in hiphil_triliteral_with_hireq.csv). The
# positional pairing of parallel_forms() goes wrong when a fragmentary scroll
# lacks an earlier form of the lexeme in the verse (e.g. 4Q76 Jon 1:7). mt_forms
# may contain more MT rows than dataset (e.g. forms without hireq).
parallel_forms_matched <- function(dataset, mt_forms = dataset) {
  mt <- mt_forms |>
    filter(scroll == 'MT') |>
    transmute(mt_match = as.numeric(tf_id), mt_g_cons = g_cons, mt_full = has_vowel_letter)
  dataset |>
    mutate(mt_match = suppressWarnings(as.numeric(mt_match))) |>
    filter(scroll != 'MT', !is.na(mt_match)) |>
    inner_join(mt, by = 'mt_match') |>
    mutate(passage = paste(book, chapter, verse, lex),
           pattern = case_when(mt_full == 1 & has_vowel_letter == 1 ~ 'both full',
                               mt_full == 0 & has_vowel_letter == 0 ~ 'both defective',
                               mt_full == 0 & has_vowel_letter == 1 ~ 'scroll fuller',
                               TRUE ~ 'MT fuller'))
}


################################################################################
# DROP-ONE COMPARISON FOR FINAL MODELS (added 2026-10-11)
#
# Credible-effects rule 4 (CLAUDE.md): for each final model, report the grouped
# k-fold comparison with the model without each of its effects.
#   - drop_one_formulas(): one formula per left-out term, named
#     '<final_id>_no_<term>'. Reuse an existing model instead when it is the
#     same formula (e.g. M3 without the suffix = M2).
#   - drop_one_kfold_table(): elpd of each reduced model minus the final model
#     (negative = the effect improves out-of-sample prediction), with SE.
#     `reduced` is a named vector: effect label -> model id in `kfolds`.
################################################################################

drop_one_formulas <- function(formula, terms, final_id) {
  set_names(map(terms, \(term) update(formula, as.formula(paste('. ~ . -', term)))),
            paste0(final_id, '_no_', terms))
}

drop_one_kfold_table <- function(kfolds, final_id, reduced) {
  imap_dfr(reduced, function(id, effect) {
    comparison <- loo::loo_compare(list(final = kfolds[[final_id]], reduced = kfolds[[id]]))
    # loo_compare sorts best first and sets the best model to 0
    tibble(effect_dropped = effect, model = id,
           elpd_diff = comparison['reduced', 'elpd_diff'] - comparison['final', 'elpd_diff'],
           se_diff = max(comparison[, 'se_diff']))
  })
}


################################################################################
# EFFECT SUMMARIES (harmonised 2026-10-17, ../TODO.md section 13)
#
# One format for every verb form: effects on the logit scale, plotted as odds
# ratios; median with 66% and 95% quantile intervals (median_qi; author,
# 2026-10-17) and pd (probability of direction).
#   - summarise_effects(): draws in long format (column `value`, logit scale)
#     -> one row per group: value (median), .lower/.upper (95%),
#     lower66/upper66 (66%), pd.
#   - coef_draws(): draws of named coefficients of a model in long format, with
#     a label per coefficient (named vector c(label = 'b_...')).
#   - plot_or(): odds-ratio plot of a summarise_effects() table.
#   - effects_not_in_final_model(): effects left out of the final model are
#     reported as "no credible effect" with their estimates from the comparison
#     models (CLAUDE.md). `specs` is a tibble with columns label, file (stored
#     model) and parameter (e.g. 'b_has_prefix1').
#   - plot_effects_not_in_final_model(): plot_or() in grey.
################################################################################

OR_BREAKS  <- c(1/64, 1/16, 1/4, 1, 4, 16, 64, 256, 1024)
OR_LABELS  <- c('1/64', '1/16', '1/4', '1', '4', '16', '64', '256', '1024')
OR_CAPTION <- 'Point: median; thick and thin line: 66% and 95% interval.'

summarise_effects <- function(draws, ...) {
  draws |>
    group_by(...) |>
    summarise(.lower  = quantile(value, 0.025),
              lower66 = quantile(value, 0.17),
              upper66 = quantile(value, 0.83),
              .upper  = quantile(value, 0.975),
              pd = max(mean(value > 0), mean(value < 0)),
              value = median(value),
              .groups = 'drop') |>
    relocate(value, .before = .lower)
}

coef_draws <- function(model, coefs) {
  d <- as_draws_df(model)
  imap_dfr(coefs, \(parameter, label)
    tibble(label = label, parameter = parameter, value = d[[parameter]]))
}

plot_or <- function(tab, y, colour = BOOK_BLUE, breaks = OR_BREAKS, labels = OR_LABELS,
                    caption = OR_CAPTION) {
  tab |>
    ggplot(aes(y = {{ y }}, x = exp(value))) +
    geom_vline(xintercept = 1, colour = BOOK_GREY, linewidth = 0.5) +
    geom_linerange(aes(xmin = exp(.lower), xmax = exp(.upper)), colour = colour,
                   linewidth = 0.6) +
    geom_linerange(aes(xmin = exp(lower66), xmax = exp(upper66)), colour = colour,
                   linewidth = 1.6) +
    geom_point(colour = colour, size = 2.5) +
    scale_x_log10(breaks = breaks, labels = labels) +
    labs(x = 'Odds ratio for full spelling (log scale)', y = NULL, caption = caption) +
    theme_book()
}

effects_not_in_final_model <- function(specs) {
  pmap_dfr(specs, function(label, file, parameter, ...) {
    m <- load_model(file)
    value <- as_draws_df(m)[[parameter]]
    rm(m); gc()
    tibble(label = label, model = sub('[.]rds$', '', file), parameter = parameter,
           value = value)
  }) |>
    mutate(label = factor(label, levels = rev(unique(specs$label)))) |>
    summarise_effects(label, model, parameter)
}

plot_effects_not_in_final_model <- function(effects_table, breaks = OR_BREAKS,
                                            labels = OR_LABELS, caption = OR_CAPTION) {
  plot_or(effects_table, label, colour = BOOK_GREY, breaks = breaks, labels = labels,
          caption = caption)
}
