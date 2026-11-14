# first_w (§8.4.2.7): the book's earlier model with corpus_group instead of
# law_phase3 (doc_group): has_vowel_letter ~ corpus_group * has_prefix +
# (1 | scr_book2/lex), model id 'nB_cg'. The author does not want doc_group in
# the book's models (2026-11-10); this model replaces nB in Table 8.36.
# Approved by the author 2026-11-10.
#
# Steps (argument):
#   fit     fit nB_cg; check that its data equal those of the stored M6;
#           print convergence, fixed effects and total effects per group
#   grouped grouped 5-fold k-fold (same folds as section 3c of analysis.R)
#   forms   5-fold k-fold over forms (same folds as section 3c2)
#   table   comparison tables with the stored k-folds (writes CSVs to
#           first_w/figures/)
#
# Usage (from the repository root):
#   Rscript analysis/ch08_nouns_adjectives/tools/fit_firstw_nb_cg.R <step>

STEP <- commandArgs(trailingOnly = TRUE)[1]
stopifnot(STEP %in% c('fit', 'grouped', 'forms', 'table'))
source('analysis/paths.R')
ANALYSIS_DIR <- CH08_DIR
LOG_DIR <- file.path(ANALYSIS_DIR, 'tools', 'logs')
dir.create(LOG_DIR, showWarnings = FALSE)
flag <- file.path(LOG_DIR, paste0('first_w_nbcg_', STEP, '_done.flag'))
unlink(flag)
stopifnot('Model folder not available' = dir.exists(file.path(MODEL_ROOT, 'analysis_nouns')))

# Sections 0-1 of the script (setup and data)
txt <- readLines(file.path(ANALYSIS_DIR, 'first_w', 'analysis.R'), encoding = 'UTF-8')
txt <- txt[seq_len(grep('^# ==== 2. EXPLORATORY ANALYSIS ====', txt) - 1)]
i <- grep('^ALLOW_FIT <- FALSE', txt); stopifnot(length(i) == 1)
txt[i] <- 'ALLOW_FIT <- TRUE'
for (e in parse(text = txt, encoding = 'UTF-8')) eval(e, globalenv())

ID <- 'nB_cg'
FORMULA <- has_vowel_letter ~ corpus_group * has_prefix + (1 | scr_book2/lex)
model_file <- function(id, scale_b = PRIOR_SD) noun_model_file(MODEL_PREFIX, id, scale_b)

# Folds exactly as in sections 3c and 3c2 of analysis.R
set.seed(2026)
folds <- loo::kfold_split_grouped(K = 5, x = as.character(dat$scr_book2))
set.seed(2026)
folds_forms <- loo::kfold_split_stratified(K = 5, x = interaction(dat$scr_book2, dat$lex, drop = TRUE))

options(width = 200)
tryCatch({
  cat('Start', STEP, format(Sys.time()), '\n')
  if (STEP == 'fit') {
    ensure_noun_model(model_file(ID), FORMULA, dat)
    m <- load_model(model_file(ID))
    m6 <- load_model(model_file('M6'))
    cols <- c('has_vowel_letter', 'corpus_group', 'has_prefix', 'scr_book2', 'lex')
    same <- all(nrow(m$data) == nrow(m6$data),
                map_lgl(cols, \(v) identical(as.character(m$data[[v]]), as.character(m6$data[[v]]))))
    cat('rows:', nrow(m$data), '; data identical to stored M6 (', paste(cols, collapse = ', '), '):', same, '\n')
    stopifnot(same)
    rm(m6); gc()
    np <- brms::nuts_params(m)
    cat('max Rhat:', round(max(brms::rhat(m), na.rm = TRUE), 3),
        '; min bulk ESS ratio:', round(min(brms::neff_ratio(m), na.rm = TRUE), 3),
        '; divergences:', sum(np$Value[np$Parameter == 'divergent__']),
        '; max treedepth hits:', sum(np$Value[np$Parameter == 'treedepth__'] >= 10), '\n')
    fixed <- as.data.frame(fixef(m, robust = TRUE, probs = c(0.025, 0.975))) |> rownames_to_column('term')
    cat('\nFixed effects (median, 95% CrI):\n'); print(mutate(fixed, across(where(is.numeric), \(x) round(x, 2))))
    print(VarCorr(m))
    total <- summarise_total_effects(noun_total_effects(m))
    cat('\nTotal effects per corpus group:\n'); print(total, n = Inf, width = 200)
    write_csv(fixed, file.path(IMAGE_FOLDER, 'table_firstw_nb_cg_fixed_effects.csv'))
    write_csv(total, file.path(IMAGE_FOLDER, 'table_firstw_nb_cg_total_effects.csv'))
  } else if (STEP == 'grouped') {
    kfold_lazy(model_file(ID), paste0(MODEL_PREFIX, ID, '_k5'), folds)
  } else if (STEP == 'forms') {
    kfold_lazy(model_file(ID), paste0(MODEL_PREFIX, ID, '_k5forms'), folds_forms)
  } else {
    ids <- c('nB', 'nB_cg', paste0('M', 0:6))
    kf <- map(set_names(ids), \(id) readRDS(file.path(MODEL_FOLDER, paste0('kfold_', MODEL_PREFIX, id, '_k5.rds'))))
    tab <- kfold_table(kf); print(tab)
    write_csv(tab, file.path(IMAGE_FOLDER, 'table_firstw_kfold.csv'))
    ids_f <- c('nB_cg', 'M2', 'M3', 'M6')
    kf_f <- map(set_names(ids_f), \(id) readRDS(file.path(MODEL_FOLDER, paste0('kfold_', MODEL_PREFIX, id, '_k5forms.rds'))))
    tab_f <- kfold_table(kf_f); print(tab_f)
    write_csv(tab_f, file.path(IMAGE_FOLDER, 'table_firstw_kfold_forms.csv'))
    # pairwise against the retained model M6 and against nB
    pair <- function(a, b, k) { cmp <- loo_compare(k[c(a, b)])
      tibble(model = b, against = a, elpd_diff = cmp[b, 'elpd_diff'] - cmp[a, 'elpd_diff'], se = max(cmp[, 'se_diff'])) }
    pairs <- bind_rows(grouped = bind_rows(pair('M6', 'nB_cg', kf), pair('nB', 'nB_cg', kf), pair('M5', 'nB_cg', kf), pair('M2', 'nB_cg', kf)),
                       forms = bind_rows(pair('M6', 'nB_cg', kf_f), pair('M3', 'nB_cg', kf_f), pair('M2', 'nB_cg', kf_f)), .id = 'kfold')
    print(pairs)
    write_csv(pairs, file.path(IMAGE_FOLDER, 'table_firstw_nb_cg_pairs.csv'))
  }
  cat('End', STEP, format(Sys.time()), '\n')
}, finally = writeLines(format(Sys.time()), flag))
