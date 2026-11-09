################################################################################
# final_w/analysis.R
#
# Dataset:  nouns_adjectives.csv, final syllable of multisyllabic stems, lexemes
#           whose optional vowel letter in that syllable is waw (book §8.2.2),
#           in the MT, SP and the biblical Dead Sea Scrolls. Only lexemes that
#           are written both full and defective (functions_nouns.R).
# Outcome:  has_vowel_letter (1 = full, e.g. GDWL; 0 = defective, GDL).
# Questions:
#   1. Do the corpora and groups of books differ (MT Pentateuch, other MT
#      books, SP, non-QSP and QSP scrolls)?
#   2. Is a suffix (pronominal suffix, nominal ending, he locale) associated
#      with defective spelling, and does that differ between corpus groups?
#   3. Is a prefix associated with defective spelling (Barr), and where?
#
# Book's model (manuscript 2026-09-10, chosen by Bayes factors):
#   has_suffix * law_phase3 + has_prefix * law_phase3 + (1 | scr_book2/lex)
#   (stored fit bayes_model_mt_sp_dss_last_n5_w.rds, 19,588 forms; Table 8.10).
#
# Status (2026-10-19): script complete; no models fitted (ALLOW_FIT = FALSE).
# 19,651 forms, 376 lexemes: the largest dataset, fitted last (author,
# 2026-10-19). FINAL_ID is chosen after the k-fold. Same structure as
# ../first_y/analysis.R, plus the book's model nB, the 1QIsaa split (835 of
# the 1,296 QSP forms) and the lexeme tables of §8.2.2.4-8.2.2.6.
#
# Started from ../../nouns_adjectives.R (sections "LAST W MODELS",
# "VISUALIZATIONS LAST WAW" and the lexeme explorations of final-syllable
# waw words). Changes against the old script:
#   - Data from read_nouns() / noun_dataset() (functions_nouns.R); 19,651
#     forms (data of 2026-10-19); the SP BRJWT correction is now in the
#     preprocessing.
#   - Harmonised with the verbs: corpus_group (MT Pentateuch reference; SP
#     own level; non-QSP one group), nested (1 | scr_book2/lex), priors
#     normal(0, 2.5) and exponential(1) instead of normal(mean, 5) and
#     student_t, grouped 5-fold k-fold instead of Bayes factors, final model
#     with credible effects only, odds ratios with quantile intervals.
#   - The lexeme tables of §8.2.2.4-8.2.2.6 (Tables 8.2-8.9) are computed
#     here.
#   - Not carried over: the MT-only affix-type models (now
#     ../affix_types_mt/analysis.R) and the older model generation of the old
#     script (law_phase2, type2, random slopes; ../TODO.md section 2).
#
# CHANGES 2026-11-03 (book §8.2.2, author's approval):
#   - Robustness fit of M6 without Barr's prefix examples GDWL/, >RWN/ and
#     YPWR/ (BARR_LEXEMES; 18,585 forms; file M6_no_barr), as in first_w.
#     Prefix in the MT Pentateuch -1.28 [-1.74, -0.83] (M6 -1.64), in MT
#     Former Prophets -0.65 [-1.28, -0.03]: both stay credible, so the
#     prefix effect does not rest on Barr's examples (unlike first_w).
#     Max Rhat 1.004, no divergences.
################################################################################


# ==== 0. SETUP ====

library(tidyverse)
library(brms)
library(bayesplot)
library(tidybayes)
library(bayestestR)
library(binom)
library(loo)

source('analysis/paths.R')
ANALYSIS_DIR <- CH08_DIR
DATASET_ID <- 'final_w'
IMAGE_FOLDER <- file.path(ANALYSIS_DIR, DATASET_ID, 'figures')

source(file.path(ANALYSIS_DIR, 'config.R'))
source(file.path(SHARED_DIR, 'functions.R'))
source(file.path(ANALYSIS_DIR, 'functions_nouns.R'))

TAG <- 'finalw'                  # figure and table names
MODEL_PREFIX <- 'na_finalw_'     # model and k-fold files in MODEL_FOLDER

# ALLOW_FIT = FALSE: only load stored results; stop instead of fitting.
ALLOW_FIT <- FALSE  # nothing fitted yet; set TRUE only after approval
options(analysis_verbs.allow_fit = ALLOW_FIT)
RUN_KFOLD <- TRUE


# ==== 1. DATA IMPORT AND PREPARATION ====

dat_all <- read_nouns()
dat <- noun_dataset(dat_all, DATASET_ID) |> add_affix_labels()

dim(dat)                                   # 19,651 forms (data of 2026-10-19)
n_distinct(dat$lex)                        # 376 lexemes
table(dat$corpus)
table(dat$corpus_group, dat$has_vowel_letter)
table(dat$corpus_group, dat$has_suffix)
table(dat$corpus_group, dat$has_prefix)
table(dat$scroll[dat$corpus == 'QSP'])     # 835 of the 1,296 QSP forms from 1QIsaa

# >LHJM/ is 21% of the data (4,079 forms): always with an ending, almost
# always defective outside the QSP scrolls (§8.2.2.5).
DOMINANT_LEXEMES <- '>LHJM/'
dat_no_dominant <- dat |> filter(!lex %in% DOMINANT_LEXEMES) |> droplevels()
dat_no_1qisaa <- dat |> filter(!scroll %in% c('1QisaaI', '1QisaaII')) |> droplevels()
# Barr's prefix examples in this dataset (Barr 1989, 23-30; §8.2.2.4, §8.5.3.1)
BARR_LEXEMES <- c('GDWL/', '>RWN/', 'YPWR/')
dat_no_barr <- dat |> filter(!lex %in% BARR_LEXEMES) |> droplevels()


# ==== 2. EXPLORATORY ANALYSIS ====

parallels <- parallel_forms(dat, occ = raw_occurrences('nominal')) |> add_mt_prefix(dat)  # raw-text pairing, 2026-11-05
write_csv(select(parallels, passage, scroll, corpus, lex, prefix, g_cons, mt_prefix, mt_g_cons,
                 has_vowel_letter, mt_full, pattern),
          file.path(IMAGE_FOLDER, paste0('table_', TAG, '_parallel_passages.csv')))

# ---- 2a. Groups, suffix, prefix, 1QIsaa, parallel passages ----
# Figs. 8.1, 8.3 and 8.4 (now by corpus group; the book's groups in
# *_groups_all).
standard <- standard_figures(dat, TAG, parallels)
standard$groups
standard$suffix
standard$prefix

# Suffix and prefix without >LHJM/ (it distorts the suffix contrast,
# §8.2.2.5)
for (affix in c('suffix', 'prefix')) {
  tab <- shares_by(dat_no_dominant, corpus_group, label = .data[[paste0(affix, '_label')]]) |>
    mutate(row = fct_rev(book_group_labels(corpus_group)))
  print(tab)
  write_csv(select(tab, -row), file.path(IMAGE_FOLDER, paste0('table_', TAG, '_', affix, '_without_elohim.csv')))
  p <- plot_shares(tab, colour_var = 'label', dodge_width = 0.6, colours = c(BOOK_BLUE, BOOK_ORANGE)) +
    labs(caption = paste0('Without ', heb_md('אלהים'), '.')) +
    markdown_caption()
  save_book_figure(p, paste0('fig_', TAG, '_', affix, '_without_elohim'), height = 9)
}

# ---- 2b. Lexemes ----

lexemes <- dat |>
  group_by(lex) |>
  summarise(n = n(), full = sum(is_full(has_vowel_letter)),
            MT = sum(corpus == 'MT'), SP = sum(corpus == 'SP'),
            `Non-QSP` = sum(corpus == 'Non-QSP'), QSP = sum(corpus == 'QSP'), .groups = 'drop') |>
  mutate(share_full = round(full / n, 2), hebrew = etcbc_to_hebrew(lex)) |>
  arrange(-n)
lexemes
write_csv(lexemes, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_lexemes.csv')))

p <- lexemes |>
  mutate(label = fct_reorder(lexeme_label(lex), share_full)) |>
  ggplot(aes(y = label, x = share_full, size = n)) +
  geom_point(colour = BOOK_BLUE, alpha = 0.8) +
  scale_x_continuous(limits = c(0, 1), labels = scales::percent) +
  scale_size_area(max_size = 6, name = 'Forms') +
  labs(x = 'Share of full spellings (all corpora)', y = NULL) +
  theme_book() +
  theme(legend.title = element_text()) +
  markdown_y()
save_book_figure(p, paste0('fig_', TAG, '_lexemes'), height = 40)

# ---- 2c. Lexeme frequencies (Fig. 8.2, Table 8.2) ----

lexeme_freqs <- dat |>
  count(lex, sort = TRUE) |>
  mutate(rank = row_number())
head(lexeme_freqs, 10)
write_csv(mutate(lexeme_freqs, hebrew = etcbc_to_hebrew(lex)),
          file.path(IMAGE_FOLDER, 'table_finalw_lexeme_frequencies.csv'))

p <- lexeme_freqs |>
  ggplot(aes(x = rank, y = n)) +
  geom_col(fill = BOOK_BLUE, width = 1) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = paste0('Lexemes, ordered by frequency (', nrow(lexeme_freqs), ' lexemes)'),
       y = 'Number of forms') +
  theme_book() +
  theme(panel.grid.major.x = element_blank())
p
save_book_figure(p, 'fig_finalw_lexeme_frequencies', height = 7)

# ---- 2d. Lexemes discussed in the book (§8.2.2.4) ----


# Spelling per corpus, with and without suffix and prefix, of the lexemes
# discussed in §8.2.2.4-8.2.2.6.
BOOK_LEXEMES <- c('>LHJM/', 'MQWM/', 'GBWL/', '>RWN/', 'GDWL/', 'QDWC/', 'CLWM/',
                  'KNWR/', 'BKR/', '>XRWN/', 'QVN/', '>ZWB/', 'JBWL/')
stopifnot(BOOK_LEXEMES %in% dat$lex)
profile <- lexeme_profile(dat, BOOK_LEXEMES)
write_csv(mutate(profile, hebrew = etcbc_to_hebrew(lex)),
          file.path(IMAGE_FOLDER, 'table_finalw_book_lexemes.csv'))

# Table 8.3: MQWM/ in the MT Pentateuch and SP, per book
pentateuch_docs <- c(paste0('MT_', LAW_BOOKS), paste0('SP_', LAW_BOOKS))
table_8_3 <- spelling_by_doc(dat, 'MQWM/', pentateuch_docs)
table_8_3
write_csv(table_8_3, file.path(IMAGE_FOLDER, 'table_finalw_mqwm_pentateuch.csv'))

# Tables 8.4-8.6: >RWN/ in parallel passages (SP; scrolls in Exodus; scrolls
# outside the Pentateuch)
table_8_4 <- parallel_crosstab(parallels, '>RWN/', 'SP')
table_8_5 <- parallel_list(parallels, '>RWN/', c('Non-QSP', 'QSP'), books = 'Exodus')
table_8_6 <- parallel_list(parallels, '>RWN/', c('Non-QSP', 'QSP'),
                           books = setdiff(unique(dat$book), LAW_BOOKS))
table_8_4; table_8_5; table_8_6
write_csv(table_8_4, file.path(IMAGE_FOLDER, 'table_finalw_arwn_sp.csv'))
write_csv(bind_rows(mutate(table_8_5, part = 'Exodus'), mutate(table_8_6, part = 'outside Pentateuch')),
          file.path(IMAGE_FOLDER, 'table_finalw_arwn_scrolls.csv'))
# Forms of >RWN/ in the scrolls (book: "23 {'21'?} times"): 23, all non-QSP
# and full (data of 2026-10-19)
dat |> filter(lex == '>RWN/', corpus %in% c('Non-QSP', 'QSP')) |> count(corpus, has_vowel_letter)

# Tables 8.7-8.8: GDWL/ in parallel passages (MT Pentateuch vs SP; MT vs
# non-QSP scrolls)
table_8_7 <- parallel_crosstab(parallels, 'GDWL/', 'SP')
table_8_8 <- parallel_crosstab(parallels, 'GDWL/', 'Non-QSP')
table_8_7; table_8_8
write_csv(bind_rows(mutate(table_8_7, comparison = 'MT Pentateuch vs SP'),
                    mutate(table_8_8, comparison = 'MT vs non-QSP')),
          file.path(IMAGE_FOLDER, 'table_finalw_gdwl_parallels.csv'))

# Table 8.9: BKR/ without suffix in the MT Pentateuch, with and without prefix
table_8_9 <- dat |>
  filter(lex == 'BKR/', corpus_group == 'MT Pentateuch', has_suffix == 0) |>
  count(prefix_label, full = is_full(has_vowel_letter)) |>
  pivot_wider(names_from = full, values_from = n, names_prefix = 'full_')
table_8_9
write_csv(table_8_9, file.path(IMAGE_FOLDER, 'table_finalw_bkr_prefix.csv'))


# ==== 3. DATA MODELLING ====
#
# Design as in the verbs (../CLAUDE.md; author, 2026-10-19):
#   - Random part nested: (1 | scr_book2/lex).
#   - corpus_group with MT Pentateuch as reference; SP its own level.
#   - Priors normal(0, 2.5) on intercept and coefficients, exponential(1) on
#     the SDs; prior sensitivity: the final model with sd 1.5 and 4.
#   - Models (functions_nouns.R): M0 null; M1 corpus; M2 corpus_group; M3 M2 +
#     has_suffix + has_prefix; M4 M3 + corpus_group x suffix; M5 M3 +
#     corpus_group x prefix; M6 both interactions. The book's model nB
#     (has_suffix * law_phase3 + has_prefix * law_phase3) for comparison.
#   - >LHJM/ stays in the data as an ordinary lexeme (as le'mor for the
#     verbs); its own intercept per scroll-book comes from the nested random
#     part. Checked by a robustness fit without >LHJM/ and in the posterior
#     predictive checks (section 5).
#   - Model choice by grouped 5-fold k-fold and the credible-effects rules
#     (no Bayes factors).
#   - Cells: 1,296 QSP and 1,579 non-QSP forms, all with and without suffix
#     and prefix.

model_specs <- c(NOUN_MODEL_SPECS,
                 list(nB = has_vowel_letter ~ has_suffix * law_phase3 + has_prefix * law_phase3 +
                        (1 | scr_book2/lex)))
model_file <- function(id, scale_b = PRIOR_SD) noun_model_file(MODEL_PREFIX, id, scale_b)

# ---- 3a. Prior predictive check ----

model_prior_only <- fit_model(model_file('M6_prior_only'), model_specs$M6, dat,
                              book_priors(PRIOR_SD), sample_prior = 'only')
prior_shares <- posterior_predict(model_prior_only, ndraws = 4000) |> rowMeans()
p <- tibble(share = prior_shares) |>
  ggplot(aes(x = share)) +
  geom_histogram(binwidth = 0.025, boundary = 0, fill = BOOK_GREY, colour = 'white',
                 linewidth = 0.3) +
  geom_vline(xintercept = mean(is_full(dat$has_vowel_letter)), colour = BOOK_BLUE,
             linewidth = 0.8) +
  scale_x_continuous(labels = scales::percent) +
  labs(x = 'Share of full spellings in a simulated dataset (prior only)',
       y = 'Number of simulations', caption = 'Blue line: observed share.') +
  theme_book()
save_book_figure(p, paste0('check_', TAG, '_prior_predictive'), height = 8)
rm(model_prior_only); gc()

# ---- 3b. Candidate models ----

iwalk(model_specs, \(formula, id) ensure_noun_model(model_file(id), formula, dat))

for (id in names(model_specs)) {
  cat('\n====', id, '====\n')
  m <- load_model(model_file(id))
  print(fixef(m))
  print(VarCorr(m))
  rm(m); gc()
}

# ---- 3c. Grouped k-fold cross-validation ----
# 5 folds; every scroll-book is left out as a whole.

set.seed(2026)
folds <- loo::kfold_split_grouped(K = 5, x = as.character(dat$scr_book2))

if (RUN_KFOLD) {
  kfolds <- map(set_names(names(model_specs)),
                \(id) kfold_lazy(model_file(id), paste0(MODEL_PREFIX, id, '_k5'), folds))
  kfold_comparison <- kfold_table(kfolds)
  kfold_comparison
  write_csv(kfold_comparison, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_kfold.csv')))
}

# ---- 3c2. Ordinary k-fold over forms (check) ----
# As in first_w and single_w (../KFOLD_ISSUE.md; author, 2026-10-26/28): the
# grouped k-fold gives a held-out scroll-book new book x lexeme effects and so
# cannot use the lexeme. Here forms are left out, stratified by scroll-book x
# lexeme cell, so that a held-out form keeps its known cell effect. The model
# structure stays nested. Only M2, M3 and M6; a check for FINAL_ID, not a
# replacement of 3c.

set.seed(2026)
folds_forms <- loo::kfold_split_stratified(K = 5, x = interaction(dat$scr_book2, dat$lex, drop = TRUE))

if (RUN_KFOLD) {
  kfolds_forms <- map(set_names(c('M2', 'M3', 'M6')),
                      \(id) kfold_lazy(model_file(id), paste0(MODEL_PREFIX, id, '_k5forms'), folds_forms))
  kfold_forms_comparison <- kfold_table(kfolds_forms)
  kfold_forms_comparison
  write_csv(kfold_forms_comparison, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_kfold_forms.csv')))
}

# ---- 3d. Robustness ----
# The fullest model M6 without >LHJM/, without 1QIsaa, and with the two halves
# of 1QIsaa as groups of their own, so that every effect can be checked
# (rule 3(i)).

isa_formula <- has_vowel_letter ~ corpus_group_isa * has_suffix + corpus_group_isa * has_prefix +
  (1 | scr_book2/lex)
robustness_specs <- list(
  no_dominant = list(file = model_file('M6_no_dominant'), formula = model_specs$M6, data = dat_no_dominant),
  no_1qisaa   = list(file = model_file('M6_no_1QIsaa'), formula = model_specs$M6, data = dat_no_1qisaa),
  isa_split   = list(file = model_file('M6_1QIsaa_split'), formula = isa_formula, data = dat),
  no_barr     = list(file = model_file('M6_no_barr'), formula = model_specs$M6, data = dat_no_barr)
)
walk(robustness_specs, \(r) ensure_noun_model(r$file, r$formula, r$data))

# ---- 3e. Final model ----
# Chosen after the k-fold with the credible-effects rules (../CLAUDE.md):
# only credible effects (95% interval excludes 0) that the k-fold does not
# clearly reject; see REPORT.md.

# M6 (author, 2026-11-01): best in the grouped k-fold (nB -36.5, SE 6.4; M4
# -66.4, SE 6.5) and in the k-fold over forms (3c2: M3 -45.1, SE 12.5; M2
# -758.1, SE 42.4).
# Reported as resting on single lexemes (rule 3(i)): suffix x SP and prefix x
# non-QSP (not credible without >LHJM/).
# Drop-one: M6 without one interaction is M4 or M5 (no new fits).
FINAL_ID <- 'M6'
stopifnot('Choose the final model (FINAL_ID) after the k-fold' = !is.na(FINAL_ID))

# Drop-one comparison (rule 4): the final model without each of its effects.
drop_one <- noun_drop_one(model_specs, FINAL_ID)
walk(drop_one, \(d) if (!d$id %in% names(model_specs)) ensure_noun_model(model_file(d$id), d$formula, dat))
if (RUN_KFOLD && length(drop_one) > 0) {
  kfolds_drop <- map(set_names(map_chr(drop_one, 'id')),
                     \(id) kfold_lazy(model_file(id), paste0(MODEL_PREFIX, id, '_k5'), folds))
  drop_one_table <- drop_one_kfold_table(c(kfolds, kfolds_drop), FINAL_ID,
                                         set_names(map_chr(drop_one, 'id'), names(drop_one)))
  drop_one_table
  write_csv(drop_one_table, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_kfold_drop_one.csv')))
}

# Prior sensitivity: the final model with sd 1.5 and 4. The sd 4 fit had
# max Rhat 1.015 (sd(scr_book2), bulk ESS 333) with 1000 / 3000; refitted
# with 2000 / 6000 (author, 2026-11-01).
ensure_noun_model(model_file(FINAL_ID, 1.5), model_specs[[FINAL_ID]], dat, scale_b = 1.5)
ensure_noun_model(model_file(FINAL_ID, 4), model_specs[[FINAL_ID]], dat, scale_b = 4,
                  warmup = 2000, iter = 6000)

final_model <- load_model(model_file(FINAL_ID))
summary(final_model)


# ==== 4. DATA VISUALISATION ====

# ---- 4a. Table of fixed effects ----

fixed_table <- make_fixed_effects_table(final_model)
fixed_table
write_csv(rownames_to_column(fixed_table, 'parameter'),
          file.path(IMAGE_FOLDER, paste0('table_', TAG, '_fixed_effects.csv')))

# ---- 4b. Effects (odds ratios) ----
# Total effects per corpus group (main effect + interaction), vs MT
# Pentateuch for the corpus groups, vs no affix for suffix and prefix.

has_effects <- has_fixed_effects(model_specs[[FINAL_ID]])
if (has_effects) {
  effects <- noun_total_effects(final_model) |> summarise_total_effects()
  effects
  write_csv(effects, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_effects.csv')))
  save_book_figure(effects_figure(effects), paste0('fig_', TAG, '_effects'), height = 12)
}

# ---- 4b2. Effects not in the final model ----
# Reported as "no credible effect" with the estimates of the comparison
# models: corpus group from M2, a common suffix or prefix effect from M3, the
# group-specific affix effects from M6.

not_in_final <- noun_effects_not_in_final(final_model, MODEL_PREFIX)
if (nrow(not_in_final) > 0) {
  not_in_final <- not_in_final |>
    summarise_effects(effect, group, model) |>
    mutate(effect_label = factor(NOUN_EFFECT_LABELS[effect], levels = NOUN_EFFECT_LABELS),
           group = factor(group, levels = rev(c(names(CORPUS_GROUP_COEF), 'All groups'))))
  not_in_final
  write_csv(not_in_final, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_effects_not_in_final_model.csv')))
  p <- effects_figure(not_in_final,
                      caption = paste0('Not in the final model; estimates from M2 (corpus group), ',
                                       'M3 (common affix effect) and M6 (affix effect per group).\n',
                                       OR_CAPTION),
                      colour = BOOK_GREY)
  save_book_figure(p, paste0('fig_', TAG, '_effects_not_in_final_model'), height = 14)
}

# ---- 4c. Predicted probability of full spelling ----
# Population level (re_formula = NA): a typical scroll-book and lexeme.

predicted <- noun_predicted(final_model, dat)
predicted
write_csv(predicted, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_predicted.csv')))

# ---- 4d. Robustness and prior sensitivity ----
# Total effects of M6 (all data, without >LHJM/, without 1QIsaa) and
# of the final model with priors sd 1.5 and 4.

robust_files <- c('M6'                     = model_file('M6'),
                  'M6 without >LHJM/'      = model_file('M6_no_dominant'),
                  'M6 without GDWL/ >RWN/ YPWR/' = model_file('M6_no_barr'),
                  'M6 without 1QIsaa'      = model_file('M6_no_1QIsaa'))
if (has_effects) {
  robust_files <- c(robust_files,
                    setNames(model_file(FINAL_ID), paste(FINAL_ID, '(final)')),
                    setNames(model_file(FINAL_ID, 1.5), paste0(FINAL_ID, ', prior sd 1.5')),
                    setNames(model_file(FINAL_ID, 4), paste0(FINAL_ID, ', prior sd 4')))
}
robustness <- imap_dfr(robust_files, function(file, variant) {
  m <- load_model(file)
  out <- noun_total_effects(m) |> summarise_effects(effect, group) |> mutate(variant = variant)
  rm(m); gc()
  out
}) |>
  mutate(effect_label = factor(paste0(NOUN_EFFECT_LABELS[effect], ': ', book_group_labels(factor(group)))),
         variant = factor(variant, levels = rev(names(robust_files))))
robustness
write_csv(robustness, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_robustness.csv')))
p <- plot_or(robustness, variant) +
  facet_wrap(~ effect_label, ncol = 3, labeller = label_wrap_gen(30))
save_book_figure(p, paste0('fig_', TAG, '_robustness'), height = 24)

# The two halves of 1QIsaa as groups of their own (M6 with corpus_group_isa)
isa_split <- load_model(model_file('M6_1QIsaa_split'))
isa_table <- noun_total_effects(isa_split, 'corpus_group_isa') |>
  filter(group %in% c('QSP', '1QIsaa I', '1QIsaa II')) |>
  summarise_total_effects()
isa_table
write_csv(isa_table, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_1qisaa_split.csv')))
rm(isa_split); gc()

# Intercept (typical document and lexeme, MT Pentateuch for models with
# corpus group) of the final model with the three priors
prior_intercepts <- map_dfr(c(PRIOR_SD, 1.5, 4), function(s) {
  m <- load_model(model_file(FINAL_ID, s))
  out <- tibble(prior_sd = s, value = as_draws_df(m)$b_Intercept) |> summarise_effects(prior_sd)
  rm(m); gc()
  out
})
prior_intercepts
write_csv(prior_intercepts, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_prior_sensitivity_intercept.csv')))

# ---- 4e. The book's model (Table 8.10) ----
# The book's model nB, refitted with the new priors and data, and the stored
# old fit (models_rstanarm, read only; 19,588 forms, old priors) for
# comparison with Table 8.10.

OLD_FIT <- file.path(OLD_MODEL_FOLDER, 'bayes_model_mt_sp_dss_last_n5_w.rds')   # old fit: only if present
book_model_table <- imap_dfr(c('nB (new)' = model_file('nB'), 'book (old fit)' = 'OLD')[c(TRUE, file.exists(OLD_FIT))],
                             function(file, fit) {
  m <- if (file == 'OLD') {
    readRDS(OLD_FIT)
  } else load_model(file)
  out <- bind_rows(
    as.data.frame(fixef(m)) |> rownames_to_column('parameter'),
    as.data.frame(VarCorr(m)$scr_book2$sd) |> mutate(parameter = 'sd(scr_book2)'),
    as.data.frame(VarCorr(m)$`scr_book2:lex`$sd) |> mutate(parameter = 'sd(scr_book2:lex)')) |>
    mutate(fit = fit, rows = nrow(m$data))
  rm(m); gc()
  out
})
book_model_table
write_csv(book_model_table, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_book_model.csv')))

# ---- 4f. Random intercepts (check) ----

p <- plot_random_intercepts(final_model, 'scr_book2', text_size = 5) + theme_book()
save_book_figure(p, paste0('check_', TAG, '_random_books'), height = 22)

lex_ranef <- ranef(final_model, robust = TRUE)$`scr_book2:lex`[, , 'Intercept'] |>
  as.data.frame() |>
  rownames_to_column('book_lex')
write_csv(lex_ranef, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_random_book_lexeme.csv')))


# ==== 5. MODEL VERIFICATION ====

# Convergence, trace and density plots, posterior predictive checks, LOO (for
# completeness; unreliable with the nested structure) and Bayes R2.
verification <- verify_model(final_model, IMAGE_FOLDER, paste0('check_', TAG))

# Observed vs predicted share of full spellings per corpus group and suffix,
# and for the most frequent lexemes.
dat$group_suffix <- factor(paste0(dat$corpus_group, if_else(dat$has_suffix == 1, ': suffix', ': no suffix')),
                           levels = paste0(rep(CORPUS_GROUP_LEVELS, each = 2), c(': no suffix', ': suffix')))
ppc_groups <- group_ppc(final_model, dat, 'group_suffix')
ppc_groups
save_book_figure(plot_ppc(ppc_groups), paste0('check_', TAG, '_ppc_groups'), height = 10)

main_lexemes <- as.character(head(lexemes$lex, 8))    # >LHJM/ first
dat$lex_main <- factor(if_else(dat$lex %in% main_lexemes, as.character(dat$lex), 'other lexemes'),
                       levels = c(main_lexemes, 'other lexemes'))
ppc_lex <- group_ppc(final_model, dat, 'lex_main')
ppc_lex
save_book_figure(plot_ppc(ppc_lex), paste0('check_', TAG, '_ppc_lexemes'), height = 7)
