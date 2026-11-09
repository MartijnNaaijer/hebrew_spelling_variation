################################################################################
# single_w/analysis.R
#
# Dataset:  nouns_adjectives.csv, monosyllabic stems, lexemes whose optional
#           vowel letter is waw (book §8.3.2), in the MT, SP and the biblical
#           Dead Sea Scrolls. Only lexemes that are written both full and
#           defective (functions_nouns.R).
# Outcome:  has_vowel_letter (1 = full, e.g. QWL; 0 = defective, QL).
# Questions:
#   1. Do the corpora and groups of books differ (MT Pentateuch, other MT
#      books, SP, non-QSP and QSP scrolls)?
#   2. Is a suffix or a prefix associated with defective spelling, and does
#      that differ between corpus groups?
#   3. How much does KL/ (53% of the data, almost always defective outside
#      the QSP scrolls) drive the results?
#
# Book's model (manuscript 2026-09-10, chosen by Bayes factors):
#   has_suffix * law_phase3 + has_prefix * law_phase3 + (1 | scr_book2/lex)
#   (stored fit bayes_model_mt_sp_dss_single_w_n5.rds, 15,334 forms; the
#   same model without KL/ in bayes_model_mt_sp_dss_single_w_n5_no_kol.rds).
#
# Status (2026-10-28): sections 3a-3d fitted (2026-10-23/25), 3c2 2026-10-27/28;
# FINAL_ID M6 (author, 2026-10-28; ../KFOLD_ISSUE.md). Prior fits to do.
# 15,351 forms, 106 lexemes. FINAL_ID is chosen after the k-fold. Same
# structure as ../first_y/analysis.R, plus the book's model nB, the 1QIsaa
# split (596 of the 971 QSP forms) and the figures without KL/ (Figs. 8.14,
# 8.16).
#
# Started from ../../nouns_adjectives.R (sections "Single syllable models
# WAW", "EXPERIMENT: SINGLE W WITHOUT KOL", "VISUALIZATIONS SINGLE WAW").
# Changes against the old script:
#   - Data from read_nouns() / noun_dataset() (functions_nouns.R); 15,351
#     forms (data of 2026-10-19).
#   - Harmonised with the verbs: corpus_group (MT Pentateuch reference; SP
#     own level; non-QSP one group), nested (1 | scr_book2/lex), priors
#     normal(0, 2.5) and exponential(1) instead of normal(mean, 5) and
#     student_t, grouped 5-fold k-fold instead of Bayes factors, final model
#     with credible effects only, odds ratios with quantile intervals.
#   - Models n1, n2 and n4 of the old script used an undefined prior mean
#     (prior_intercept_logit); not carried over.
################################################################################


# ==== 0. SETUP ====

library(tidyverse)
library(brms)
library(bayesplot)
library(tidybayes)
library(bayestestR)
library(binom)
library(loo)

ANALYSIS_DIR <- 'C:/Users/geitb/Dropbox/monograph_orthography/nouns_adjectives/analysis_nouns'
DATASET_ID <- 'single_w'
IMAGE_FOLDER <- file.path(ANALYSIS_DIR, DATASET_ID, 'figures')

source(file.path(ANALYSIS_DIR, 'config.R'))
source(file.path(VERBS_DIR, 'functions.R'))
source(file.path(ANALYSIS_DIR, 'functions_nouns.R'))

TAG <- 'singlew'                 # figure and table names
MODEL_PREFIX <- 'na_singlew_'    # model and k-fold files in MODEL_FOLDER

# ALLOW_FIT = FALSE: only load stored results; stop instead of fitting.
ALLOW_FIT <- FALSE  # nothing fitted yet; set TRUE only after approval
options(analysis_verbs.allow_fit = ALLOW_FIT)
RUN_KFOLD <- TRUE


# ==== 1. DATA IMPORT AND PREPARATION ====

dat_all <- read_nouns()
dat <- noun_dataset(dat_all, DATASET_ID) |> add_affix_labels()

dim(dat)                                   # 15,351 forms (data of 2026-10-19)
n_distinct(dat$lex)                        # 106 lexemes
table(dat$corpus)
table(dat$corpus_group, dat$has_vowel_letter)
table(dat$corpus_group, dat$has_suffix)
table(dat$corpus_group, dat$has_prefix)
table(dat$scroll[dat$corpus == 'QSP'])     # 596 of the 971 QSP forms from 1QIsaa

# KL/ is 53% of the data (8,110 forms): defective in the MT (one full form)
# and SP, mostly full in the QSP scrolls, and almost never suffixed in the MT
# and SP (§8.3.2.5).
DOMINANT_LEXEMES <- 'KL/'
dat_no_dominant <- dat |> filter(!lex %in% DOMINANT_LEXEMES) |> droplevels()
dat_no_1qisaa <- dat |> filter(!scroll %in% c('1QisaaI', '1QisaaII')) |> droplevels()


# ==== 2. EXPLORATORY ANALYSIS ====

parallels <- parallel_forms(dat, occ = raw_occurrences('nominal')) |> add_mt_prefix(dat)  # raw-text pairing, 2026-11-05
write_csv(select(parallels, passage, scroll, corpus, lex, prefix, g_cons, mt_prefix, mt_g_cons,
                 has_vowel_letter, mt_full, pattern),
          file.path(IMAGE_FOLDER, paste0('table_', TAG, '_parallel_passages.csv')))

# ---- 2a. Groups, suffix, prefix, 1QIsaa, parallel passages ----
# Figs. 8.12, 8.13 and 8.15 (now by corpus group; the book's groups in
# *_groups_all).
standard <- standard_figures(dat, TAG, parallels)
standard$groups
standard$suffix
standard$prefix

# Figs. 8.14 and 8.16: suffix and prefix without KL/
for (affix in c('suffix', 'prefix')) {
  tab <- shares_by(dat_no_dominant, corpus_group, label = .data[[paste0(affix, '_label')]]) |>
    mutate(row = fct_rev(book_group_labels(corpus_group)))
  print(tab)
  write_csv(select(tab, -row), file.path(IMAGE_FOLDER, paste0('table_', TAG, '_', affix, '_without_kol.csv')))
  p <- plot_shares(tab, colour_var = 'label', dodge_width = 0.6, colours = c(BOOK_BLUE, BOOK_ORANGE)) +
    labs(caption = paste0('Without ', heb_md('כל'), '.')) +
    markdown_caption()
  save_book_figure(p, paste0('fig_', TAG, '_', affix, '_without_kol'), height = 9)
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
save_book_figure(p, paste0('fig_', TAG, '_lexemes'), height = 12)

# ---- 2c. Lexemes discussed in the book (§8.3.2.4) ----
# Book: KL/ MT 5,408 (1 full, Jer 31:34), SP 1,654 defective, non-QSP 69 full
# and 545 defective, QSP 410 full and 23 defective; per scroll (1Q8, 4Q22,
# Mur88, 4Q41, 4Q51, 4Q130, 4Q83, 4Q98, 11Q5, 1QIsaa I/II, 4Q136). XQ/ MT 126
# (1 full), SP 50 defective; 20 non-QSP parallels (3 full); QSP 24 all full.
# RB=/ MT 149 (2 full), SP 12, non-QSP 13 (1 full), QSP all full. QWL/ MT 505
# (62 defective), SP 106 full; Table 8.16; QSP 56 full. <LH/ MT 286 (48
# full), MT Pentateuch 4 of 148 full; Table 8.17. <WR=/ MT Pentateuch 19
# defective, 61 full. XWMH/ MT 133 (23 defective); Tables 8.18 and 8.19.

BOOK_LEXEMES <- c('KL/', 'XQ/', 'RB=/', 'QWL/', '<LH/', '<WR=/', 'XWMH/')
stopifnot(BOOK_LEXEMES %in% dat$lex)
profile <- lexeme_profile(dat, BOOK_LEXEMES)
profile
write_csv(mutate(profile, hebrew = etcbc_to_hebrew(lex)),
          file.path(IMAGE_FOLDER, paste0('table_', TAG, '_book_lexemes.csv')))

dat |> filter(lex %in% BOOK_LEXEMES) |>
  count(lex, corpus, full = is_full(has_vowel_letter)) |>
  pivot_wider(names_from = full, values_from = n, names_prefix = 'full_', values_fill = 0)
dat |> filter(lex %in% c('<LH/', '<WR=/', 'XWMH/'), corpus == 'MT') |>
  count(lex, corpus_group, full = is_full(has_vowel_letter)) |>
  pivot_wider(names_from = full, values_from = n, names_prefix = 'full_', values_fill = 0)

# KL/ per scroll
kol_scrolls <- dat |>
  filter(lex == 'KL/', corpus %in% c('Non-QSP', 'QSP')) |>
  count(corpus, scroll, full = is_full(has_vowel_letter)) |>
  pivot_wider(names_from = full, values_from = n, names_prefix = 'full_', values_fill = 0) |>
  arrange(corpus, desc(full_TRUE + full_FALSE))
kol_scrolls
write_csv(kol_scrolls, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_kol_scrolls.csv')))

# Table 8.16 (QWL/, MT vs non-QSP) and the parallel lists of Tables 8.17-8.19
book_crosstabs <- bind_rows(
  parallel_crosstab(parallels, 'QWL/', 'Non-QSP') |> mutate(table = '8.16 QWL/ non-QSP'),
  parallel_crosstab(parallels, 'XQ/', 'Non-QSP') |> mutate(table = 'XQ/ non-QSP'))
book_crosstabs
write_csv(book_crosstabs, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_book_crosstabs.csv')))
book_parallels <- bind_rows(
  parallel_list(parallels, '<LH/', 'QSP') |> mutate(table = '8.17 <LH/ QSP'),
  parallel_list(parallels, '<LH/', 'Non-QSP') |> mutate(table = '<LH/ non-QSP'),
  parallel_list(parallels, 'XWMH/', 'SP') |> mutate(table = '8.18 XWMH/ SP'),
  parallel_list(parallels, 'XWMH/', c('Non-QSP', 'QSP')) |> mutate(table = '8.19 XWMH/ scrolls'),
  parallel_list(parallels, 'RB=/', 'QSP') |> mutate(table = 'RB=/ QSP'))
book_parallels
write_csv(book_parallels, file.path(IMAGE_FOLDER, paste0('table_', TAG, '_book_parallels.csv')))


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
#   - KL/ stays in the data as an ordinary lexeme (as le'mor for the verbs);
#     its own intercept per scroll-book comes from the nested random part.
#     Checked by a robustness fit without KL/ and in the posterior
#     predictive checks (section 5).
#   - Model choice by grouped 5-fold k-fold and the credible-effects rules
#     (no Bayes factors).
#   - Cells: 971 QSP and 1,161 non-QSP forms, all with and without suffix
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
# Option (c) of ../KFOLD_ISSUE.md (author, 2026-10-26): the grouped k-fold
# gives a held-out scroll-book new book x lexeme effects (sd about 9-10) and so
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
# The fullest model M6 without KL/, without 1QIsaa, and with the two halves
# of 1QIsaa as groups of their own, so that every effect can be checked
# (rule 3(i)).

isa_formula <- has_vowel_letter ~ corpus_group_isa * has_suffix + corpus_group_isa * has_prefix +
  (1 | scr_book2/lex)
robustness_specs <- list(
  no_dominant = list(file = model_file('M6_no_dominant'), formula = model_specs$M6, data = dat_no_dominant),
  no_1qisaa   = list(file = model_file('M6_no_1QIsaa'), formula = model_specs$M6, data = dat_no_1qisaa),
  isa_split   = list(file = model_file('M6_1QIsaa_split'), formula = isa_formula, data = dat)
)
walk(robustness_specs, \(r) ensure_noun_model(r$file, r$formula, r$data))

# ---- 3e. Final model ----
# Chosen after the k-fold with the credible-effects rules (../CLAUDE.md):
# only credible effects (95% interval excludes 0) that the k-fold does not
# clearly reject; see REPORT.md.

# M6 (author, 2026-10-28): option (a) of ../KFOLD_ISSUE.md. All its terms
# are credible; the grouped k-fold over scr_book2 cannot use the nested
# lexeme effects (rule 4), and the k-fold over forms (3c2) prefers M6:
# M3 -8.7 (SE 7.4), M2 -182.6 (SE 20.7).
# Reported as resting on single lexemes (rule 3(i)): QSP x prefix and
# non-QSP x suffix (KL/).
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
# max Rhat 1.015 (sd(scr_book2), bulk ESS 500) with 1000 / 3000; refitted
# with 2000 / 6000 (author, 2026-10-28).
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
# Total effects of M6 (all data, without KL/, without 1QIsaa) and
# of the final model with priors sd 1.5 and 4.

robust_files <- c('M6'                     = model_file('M6'),
                  'M6 without KL/'         = model_file('M6_no_dominant'),
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

# ---- 4e. The book's model (Table 8.20) ----
# The book's model nB, refitted with the new priors and data, and the stored
# old fit (models_rstanarm, read only; 15,334 forms, old priors) for
# comparison with Table 8.20.

book_model_table <- imap_dfr(c('nB (new)' = model_file('nB'), 'book (old fit)' = 'OLD'),
                             function(file, fit) {
  m <- if (file == 'OLD') {
    readRDS('D:/brms_models_spelling/models_rstanarm/bayes_model_mt_sp_dss_single_w_n5.rds')
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

main_lexemes <- as.character(head(lexemes$lex, 8))    # KL/ first
dat$lex_main <- factor(if_else(dat$lex %in% main_lexemes, as.character(dat$lex), 'other lexemes'),
                       levels = c(main_lexemes, 'other lexemes'))
ppc_lex <- group_ppc(final_model, dat, 'lex_main')
ppc_lex
save_book_figure(plot_ppc(ppc_lex), paste0('check_', TAG, '_ppc_lexemes'), height = 7)
