# Check of the data update of 2026-11-03 (hebrew_spelling_variation 37b4f01,
# MASCULINE_ROOT_H_LEXEMES): has_suffix 1 -> 0 for 2 final_w and 9 single_w
# scroll forms; nothing else changed in the six datasets. Fits M6 once on the
# new data (file *_M6_data20261103.rds; the stored M6 stays) and compares the
# fixed effects and total effects per corpus group with the stored M6.
# Approved by the author 2026-11-03.
#
# Usage (from a scratch folder):
#   Rscript <analysis_nouns>/run/refit_m6_newdata.R <final_w|single_w>

ID <- commandArgs(trailingOnly = TRUE)[1]
stopifnot(ID %in% c('final_w', 'single_w'))
ANALYSIS_DIR <- 'C:/Users/geitb/Dropbox/monograph_orthography/nouns_adjectives/analysis_nouns'
LOG_DIR <- file.path(ANALYSIS_DIR, 'run', 'logs')
flag <- file.path(LOG_DIR, paste0(ID, '_m6new_done.flag'))
unlink(flag)
stopifnot('Model folder (drive D:) not available' = dir.exists('D:/brms_models_spelling/analysis_nouns'))

# Sections 0-1 of the script (setup and data)
txt <- readLines(file.path(ANALYSIS_DIR, ID, 'analysis.R'), encoding = 'UTF-8')
txt <- txt[seq_len(grep('^# ==== 2. EXPLORATORY ANALYSIS ====', txt) - 1)]
i <- grep('^ALLOW_FIT <- FALSE', txt); stopifnot(length(i) == 1)
txt[i] <- 'ALLOW_FIT <- TRUE'
for (e in parse(text = txt, encoding = 'UTF-8')) eval(e, globalenv())

tryCatch({
  cat('Start', ID, format(Sys.time()), '\n')
  file_new <- noun_model_file(MODEL_PREFIX, 'M6_data20261103')
  ensure_noun_model(file_new, NOUN_MODEL_SPECS$M6, dat)
  cat('Fitted', format(Sys.time()), '\n')
  m_old <- load_model(noun_model_file(MODEL_PREFIX, 'M6'))
  m_new <- load_model(file_new)
  cat('rows old/new:', nrow(m_old$data), nrow(m_new$data),
      '; has_suffix changed in', sum(m_old$data$has_suffix != m_new$data$has_suffix), 'rows\n')
  cat('max Rhat new:', round(max(brms::rhat(m_new), na.rm = TRUE), 3),
      '; divergences:', sum(brms::nuts_params(m_new)$Value[brms::nuts_params(m_new)$Parameter == 'divergent__']), '\n')
  fx <- function(m) as.data.frame(fixef(m, robust = TRUE, probs = c(0.025, 0.975))) |>
    rownames_to_column('term')
  fixed <- full_join(fx(m_old), fx(m_new), by = 'term', suffix = c('_old', '_new')) |>
    mutate(diff = Estimate_new - Estimate_old)
  options(width = 200)
  cat('\nFixed effects (medians, 95% CrI), old vs new:\n')
  print(mutate(fixed, across(where(is.numeric), \(x) round(x, 3))))
  tot <- function(m) summarise_total_effects(noun_total_effects(m))
  t_old <- tot(m_old); t_new <- tot(m_new)
  cat('\nTotal effects, old:\n'); print(t_old, n = Inf, width = 200)
  cat('\nTotal effects, new:\n'); print(t_new, n = Inf, width = 200)
  write_csv(fixed, file.path(LOG_DIR, paste0(ID, '_m6new_fixed.csv')))
  write_csv(bind_rows(old = t_old, new = t_new, .id = 'data'),
            file.path(LOG_DIR, paste0(ID, '_m6new_total.csv')))
  cat('End', ID, format(Sys.time()), '\n')
}, finally = writeLines(format(Sys.time()), flag))
