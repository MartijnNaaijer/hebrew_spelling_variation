################################################################################
# Chapter 12: weights for the model-based null (revision 2026-11-13)
#
# For every MT form of the two features, the posterior mean of the linear
# predictor (logit) of the chapter 9 final model: ptca_qal M7 (ptca_M7.rds),
# infc_qal_triliteral M2 (infc2_M2.rds). Only stored fits are read; nothing is
# fitted. Book-level terms (corpus group, book intercept) are constant within a
# book and cancel in the conditional Bernoulli null of sequence_analysis.R; what
# matters is the variation within a book: suffix, prefix, verb class and the
# book x lexeme effects, which are shrunk towards zero (partial pooling).
#
# Output: results/model_weights.tsv (feature, tf_id, scroll, eta, new_level).
# Run from the repository root, before sequence_analysis.R:
#   Rscript analysis/ch12_sequences/model_weights.R   (a few minutes; needs the stored chapter 9 fits)
################################################################################

suppressMessages({ library(tidyverse); library(brms) })

source('analysis/paths.R')
HERE <- CH12_DIR
DATA <- CLEANED_DATA_DIR
MODEL_FOLDER <- file.path(MODEL_ROOT, 'analysis_verbs')
YOD_VERBS <- c('JBC[', 'JNQ[', 'JCR[', 'JVB[', 'JQY[', 'JLL[', 'JMN[')   # as in ../shared/config.R
MODELS <- c(ptca_qal = 'ptca_M7.rds', infc_qal_triliteral = 'infc2_M2.rds')

prepare <- function(feature, model) {
  d <- read_tsv(file.path(DATA, paste0('cleaned_', feature, '.tsv')), col_types = cols(.default = 'c')) |>
    filter(scroll == 'MT') |>
    mutate(tf_id = as.integer(tf_id))
  md <- model$data
  # the model's own coding of each predictor (factor or numeric)
  as_model <- function(x, name) {
    if (!name %in% names(md)) return(NULL)
    if (is.factor(md[[name]])) factor(x, levels = levels(md[[name]])) else as.numeric(x)
  }
  nd <- tibble(tf_id = d$tf_id, scroll = d$scroll, lex = d$lex, scr_book2 = d$scr_book2)
  nd$corpus_group <- as_model(d$corpus_group, 'corpus_group')
  for (v in c('has_suffix', 'has_prefix')) if (v %in% names(md)) nd[[v]] <- as_model(d[[v]], v)
  if ('ay_ay' %in% names(md)) nd$ay_ay <- as_model(as.numeric(substr(d$lex, 2, 2) == substr(d$lex, 3, 3)), 'ay_ay')
  if ('i_yod' %in% names(md)) nd$i_yod <- as_model(as.numeric((substr(d$lex, 1, 1) == 'J' & !(d$lex %in% YOD_VERBS)) |
                                                                d$lex == 'HLK['), 'i_yod')
  stopifnot(!anyNA(nd$corpus_group))
  nd$new_level <- !paste(nd$scr_book2, nd$lex, sep = '_') %in% unique(paste(md$scr_book2, md$lex, sep = '_'))
  nd
}

out <- list()
for (f in names(MODELS)) {
  t0 <- Sys.time()
  m <- readRDS(file.path(MODEL_FOLDER, MODELS[[f]]))
  nd <- prepare(f, m)
  message(f, ': ', nrow(nd), ' MT forms; ', sum(nd$new_level), ' with a book x lexeme level not in the fit')
  # new levels (if any) get a random effect of zero (sample_new_levels = 'gaussian' averages to 0 over draws
  # only approximately; use the mean of the population instead)
  eta <- posterior_linpred(m, newdata = nd, allow_new_levels = TRUE, sample_new_levels = 'old_levels',
                           re_formula = NULL)
  out[[f]] <- tibble(feature = f, tf_id = nd$tf_id, scroll = nd$scroll, eta = colMeans(eta), new_level = nd$new_level)
  rm(m, eta); gc()
  message(f, ': ', round(difftime(Sys.time(), t0, units = 'mins'), 1), ' min')
}
write_tsv(bind_rows(out), file.path(HERE, 'results', 'model_weights.tsv'))
