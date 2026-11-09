# Check of the data update of 2026-11-03 (hebrew_spelling_variation
# 6cbee1a..37b4f01, DSS segmentation fixes) for the verb models. Only three
# final verb models have changed model data (scroll forms only):
#   ptcp_qal M7: `ending` none -> fem_sg for 49 forms; 4 forms out, 2 in;
#   ptca_qal M7: `has_suffix` 0 -> 1 for 24 forms;
#   hiphil_triliteral M7: `has_suffix` changed for 8 forms.
# Refits the stored final model on the new data with update() (same formula,
# priors and sampler settings), under the name *_M7_data20261103.rds (the
# stored model stays), and compares the fixed effects. Requested by the author
# 2026-11-04 ("test the verb models as well").
#
# Usage (from a scratch folder):  Rscript refit_verbs_newdata.R <id>

ID <- commandArgs(trailingOnly = TRUE)[1]
PREFIX <- c(ptcp_qal = 'ptcp_d2_', ptca_qal = 'ptca_', hiphil_triliteral = 'hif_')
stopifnot(ID %in% names(PREFIX))
VERBS_DIR <- 'C:/Users/geitb/Dropbox/monograph_orthography/verbs/analysis_verbs'
LOG_DIR <- 'C:/Users/geitb/Dropbox/monograph_orthography/nouns_adjectives/analysis_nouns/run/logs'
flag <- file.path(LOG_DIR, paste0(ID, '_m7new_done.flag'))
unlink(flag)
stopifnot('Model folder (drive D:) not available' = dir.exists('D:/brms_models_spelling/analysis_verbs'))

# Sections 0-1 of the verb script (setup and data, current data folder)
txt <- readLines(file.path(VERBS_DIR, ID, 'analysis.R'), encoding = 'UTF-8')
txt <- txt[seq_len(grep('^# ==== 2. EXPLORATORY ANALYSIS ====', txt) - 1)]
for (e in parse(text = txt, encoding = 'UTF-8')) eval(e, globalenv())

tryCatch({
  cat('Start', ID, format(Sys.time()), '\n')
  file_old <- file.path(MODEL_FOLDER, paste0(PREFIX[[ID]], 'M7.rds'))
  file_new <- file.path(MODEL_FOLDER, paste0(PREFIX[[ID]], 'M7_data20261103.rds'))
  m_old <- readRDS(file_old)
  if (file.exists(file_new)) {
    m_new <- readRDS(file_new)
  } else {
    m_new <- update(m_old, newdata = dat, recompile = FALSE, seed = 20261104)
    saveRDS(m_new, file_new)
  }
  cat('Fitted', format(Sys.time()), '\n')
  cat('rows old/new:', nrow(m_old$data), nrow(m_new$data), '\n')
  s <- function(m) c(chains = brms::nchains(m), iter = m$fit@sim$iter, warmup = m$fit@sim$warmup)
  cat('sampler old:', s(m_old), '; new:', s(m_new), '\n')
  cat('max Rhat new:', round(max(brms::rhat(m_new), na.rm = TRUE), 3),
      '; divergences:', sum(brms::nuts_params(m_new)$Value[brms::nuts_params(m_new)$Parameter == 'divergent__']), '\n')
  fx <- function(m) {
    d <- brms::as_draws_df(m)
    b <- d[, grep('^b_', names(d))]
    tibble::tibble(term = sub('^b_', '', names(b)),
                   median = sapply(b, median),
                   lower95 = sapply(b, quantile, 0.025), upper95 = sapply(b, quantile, 0.975),
                   pd = sapply(b, \(x) max(mean(x > 0), mean(x < 0))))
  }
  fixed <- dplyr::full_join(fx(m_old), fx(m_new), by = 'term', suffix = c('_old', '_new')) |>
    dplyr::mutate(diff = median_new - median_old,
                  credible_old = pd_old >= 0.975, credible_new = pd_new >= 0.975)
  options(width = 220)
  print(as.data.frame(dplyr::mutate(fixed, dplyr::across(where(is.numeric), \(x) round(x, 3)))))
  cat('\nTerms whose credibility (pd >= 0.975) changed:',
      paste(fixed$term[fixed$credible_old != fixed$credible_new], collapse = ', '), '\n')
  readr::write_csv(fixed, file.path(LOG_DIR, paste0(ID, '_m7new_fixed.csv')))
  cat('End', ID, format(Sys.time()), '\n')
}, finally = writeLines(format(Sys.time()), flag))
