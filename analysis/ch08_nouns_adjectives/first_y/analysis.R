################################################################################
# first_y/analysis.R
#
# Dataset:  nouns_adjectives.csv, first syllable of multisyllabic stems, lexemes
#           whose optional vowel letter in that syllable is yod (book §8.4.3),
#           in the MT, SP and the biblical Dead Sea Scrolls. Only lexemes that
#           are written both full and defective (functions_nouns.R).
# Outcome:  has_vowel_letter (1 = full, e.g. PJLGC; 0 = defective, PLGC).
# Questions:
#   1. Do the corpora and groups of books differ (MT Pentateuch, other MT
#      books, SP, non-QSP and QSP scrolls)?
#   2. Is a suffix or a prefix associated with defective spelling?
#
# Book's model (manuscript 2026-09-10, chosen by Bayes factors): intercept only,
#   has_vowel_letter ~ 1 + (1 | scr_book2/lex)
#   (stored fit bayes_model_mt_sp_dss_first_n0_j.rds, 802 forms; Table 8.33).
#
# Status (2026-10-20): all models fitted; final model M0 (author,
# 2026-10-20). Results in REPORT.md.
#
# Started from ../../nouns_adjectives.R (sections "First syllable models
# YOD", "VISUALIZATIONS FIRST YOD"). Changes against the old script:
#   - Data from read_nouns() / noun_dataset() (functions_nouns.R); 776 forms
#     instead of 802 (data of 2026-10-19).
#   - Harmonised with the verbs: corpus_group (MT Pentateuch reference; SP
#     own level; non-QSP one group), nested (1 | scr_book2/lex), priors
#     normal(0, 2.5) and exponential(1) instead of normal(mean, 5) and
#     student_t, grouped 5-fold k-fold instead of Bayes factors, final model
#     with credible effects only, odds ratios with quantile intervals.
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
DATASET_ID <- 'first_y'
IMAGE_FOLDER <- file.path(ANALYSIS_DIR, DATASET_ID, 'figures')

source(file.path(ANALYSIS_DIR, 'config.R'))
source(file.path(SHARED_DIR, 'functions.R'))
source(file.path(ANALYSIS_DIR, 'functions_nouns.R'))

TAG <- 'firsty'                  # figure and table names
MODEL_PREFIX <- 'na_firsty_'     # model and k-fold files in MODEL_FOLDER

# ALLOW_FIT = FALSE: only load stored results; stop instead of fitting.
ALLOW_FIT <- FALSE  # all fits stored (2026-10-20); TRUE only after approval
options(analysis_verbs.allow_fit = ALLOW_FIT)
RUN_KFOLD <- TRUE


# ==== 1. DATA IMPORT AND PREPARATION ====

dat_all <- read_nouns()
dat <- noun_dataset(dat_all, DATASET_ID) |> add_affix_labels()

dim(dat)                                   # 776 forms (data of 2026-10-19)
n_distinct(dat$lex)                        # 23 lexemes (book: "23 {or 24?}")
table(dat$corpus)
table(dat$corpus_group, dat$has_vowel_letter)
table(dat$corpus_group, dat$has_suffix)
table(dat$corpus_group, dat$has_prefix)
table(dat$scroll[dat$corpus == 'QSP'])     # 30 of the 40 QSP forms from 1QIsaa

# Two lexemes make up almost half of the data and are almost always defective:
# GBWR/ (191 forms, 2 full, both in SP) and XLB=/ (177 forms, 1 full).
DOMINANT_LEXEMES <- c('GBWR/', 'XLB=/')
dat_no_dominant <- dat |> filter(!lex %in% DOMINANT_LEXEMES) |> droplevels()
dat_no_1qisaa <- dat |> filter(!scroll %in% c('1QisaaI', '1QisaaII')) |> droplevels()
# The SP effect of M1-M3 rests on KTNT/ (20 of the 27 parallels where SP is
# fuller; SP vocalisation kittanet, §8.4.3.4): check fit of M2 without it.
dat_no_ktnt <- dat |> filter(lex != 'KTNT/') |> droplevels()


# ==== 2. EXPLORATORY ANALYSIS ====

parallels <- parallel_forms(dat, occ = raw_occurrences('nominal')) |> add_mt_prefix(dat)  # raw-text pairing, 2026-11-05
write_csv(select(parallels, passage, scroll, corpus, lex, prefix, g_cons, mt_prefix, mt_g_cons,
                 has_vowel_letter, mt_full, pattern),
          file.path(IMAGE_FOLDER, paste0('table_', TAG, '_parallel_passages.csv')))

# ---- 2a. Groups, suffix, prefix, 1QIsaa, parallel passages ----
# Figs. 8.29-8.31 (now by corpus group; the book's groups in *_groups_all).
standard <- standard_figures(dat, TAG, parallels)
standard$groups
standard$suffix
standard$prefix

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

# ---- 2c. Lexemes discussed in the book (§8.4.3.4) ----
# Book: GBWR/ 158 MT, 15 non-QSP, 12 QSP, all defective; 6 in SP, 2 full
# (Exod 15:3, Deut 10:17). TJMN/ 38 forms, 1 defective (Job 9:9). >JTN/ 18
# (14 MT, 4 SP). G>WT/ 14 (8 MT, 6 QSP; 1 full, 1QIsaa Isa 9:17). PLGC/ 45.
# KTNT/ defective in MT (29), non-QSP (4), QSP (1); full in SP.

BOOK_LEXEMES <- c('GBWR/', 'TJMN/', '>JTN/', 'G>WT/', 'PLGC/', 'KTNT/')
stopifnot(BOOK_LEXEMES %in% dat$lex)
profile <- lexeme_profile(dat, BOOK_LEXEMES)
profile
write_csv(mutate(profile, hebrew = etcbc_to_hebrew(lex)),
          file.path(IMAGE_FOLDER, paste0('table_', TAG, '_book_lexemes.csv')))

dat |> filter(lex == 'GBWR/', is_full(has_vowel_letter)) |>
  select(scroll, book, chapter, verse, prefix, g_cons)
dat |> filter(lex == 'TJMN/', !is_full(has_vowel_letter)) |>
  select(scroll, book, chapter, verse, prefix, g_cons)
dat |> filter(lex == 'G>WT/', is_full(has_vowel_letter)) |>
  select(scroll, book, chapter, verse, prefix, g_cons)
spelling_by_doc(dat, 'PLGC/')
dat |> filter(lex == 'KTNT/') |> count(corpus, full = is_full(has_vowel_letter))


# ==== 3. DATA MODELLING ====
#
# Design as in the verbs (../CLAUDE.md; author, 2026-10-19):
#   - Random part nested: (1 | scr_book2/lex).
#   - corpus_group with MT Pentateuch as reference; SP its own level.
#   - Priors normal(0, 2.5) on intercept and coefficients, exponential(1) on
#     the SDs; prior sensitivity: the final model with sd 1.5 and 4.
#   - Models (functions_nouns.R): M0 null; M1 corpus; M2 corpus_group; M3 M2 +
#     has_suffix + has_prefix; M4 M3 + corpus_group x suffix; M5 M3 +
#     corpus_group x prefix; M6 both interactions. The book's model is M0.
#   - Model choice by grouped 5-fold k-fold and the credible-effects rules
#     (no Bayes factors).
#   - Small cells: 40 QSP and 48 non-QSP forms, so the corpus group x affix
#     interactions of M4-M6 rest largely on the prior.

model_specs <- NOUN_MODEL_SPECS        # the book's model is M0
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

# ---- 3d. Robustness ----
# The fullest model M6 without the two dominant lexemes and without 1QIsaa,
# so that every effect can be checked (rule 3(i)). With 30 forms, 1QIsaa is
# not split into its two halves here.

robustness_specs <- list(
  no_dominant = list(file = model_file('M6_no_dominant'), data = dat_no_dominant),
  no_1qisaa   = list(file = model_file('M6_no_1QIsaa'), data = dat_no_1qisaa)
)
walk(robustness_specs, \(r) ensure_noun_model(r$file, model_specs$M6, r$data))
ensure_noun_model(model_file('M2_no_KTNT'), model_specs$M2, dat_no_ktnt)

# ---- 3e. Final model ----
# Chosen after the k-fold with the credible-effects rules (../CLAUDE.md):
# only credible effects (95% interval excludes 0) that the k-fold does not
# clearly reject; see REPORT.md.

# M0 (author, 2026-10-20): the only credible effect, SP vs MT Pentateuch in
# M1-M3, is a lexeme effect of KTNT/ (rule 3(i)), and the k-fold clearly
# prefers M0 (M2 -31.5, SE 6.2). No drop-one: M0 has no effects.
FINAL_ID <- 'M0'
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
# max Rhat 1.012 with 1000 / 3000; refitted with 2000 / 6000 (author,
# 2026-10-20).
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
# Total effects of M2 (all data, without KTNT/), of M6 (all data, without
# GBWR/ and XLB=/, without 1QIsaa) and of the final model with priors sd 1.5
# and 4 (only if it has effects).

robust_files <- c('M2'                     = model_file('M2'),
                  'M2 without KTNT/'       = model_file('M2_no_KTNT'),
                  'M6'                     = model_file('M6'),
                  'M6 without GBWR/ XLB=/' = model_file('M6_no_dominant'),
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

# ---- 4e. The book's model (Table 8.33) ----
# The book's model is M0 (refitted here with the new priors and data). The
# stored old fit (models_rstanarm, read only; 802 forms, old priors) for
# comparison with Table 8.33: intercept -3.66 [-6.05, -1.90], sd(book) 1.76,
# sd(lex:book) 9.16.

m0 <- load_model(model_file('M0'))
book_model_table <- bind_rows(
  as.data.frame(fixef(m0)) |> rownames_to_column('parameter') |> mutate(fit = 'M0 (new)'),
  as.data.frame(VarCorr(m0)$scr_book2$sd) |> rownames_to_column('parameter') |>
    mutate(parameter = 'sd(scr_book2)', fit = 'M0 (new)'),
  as.data.frame(VarCorr(m0)$`scr_book2:lex`$sd) |> rownames_to_column('parameter') |>
    mutate(parameter = 'sd(scr_book2:lex)', fit = 'M0 (new)'))
rm(m0); gc()
OLD_FIT <- file.path(OLD_MODEL_FOLDER, 'bayes_model_mt_sp_dss_first_n0_j.rds')   # old fit: only if present
if (file.exists(OLD_FIT)) {
old_fit <- readRDS(OLD_FIT)
book_model_table <- bind_rows(
  book_model_table,
  as.data.frame(fixef(old_fit)) |> rownames_to_column('parameter') |> mutate(fit = 'book (old fit)'),
  as.data.frame(VarCorr(old_fit)$scr_book2$sd) |> rownames_to_column('parameter') |>
    mutate(parameter = 'sd(scr_book2)', fit = 'book (old fit)'),
  as.data.frame(VarCorr(old_fit)$`scr_book2:lex`$sd) |> rownames_to_column('parameter') |>
    mutate(parameter = 'sd(scr_book2:lex)', fit = 'book (old fit)'))
rm(old_fit); gc()
}
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

main_lexemes <- as.character(head(lexemes$lex, 8))
dat$lex_main <- factor(if_else(dat$lex %in% main_lexemes, as.character(dat$lex), 'other lexemes'),
                       levels = c(main_lexemes, 'other lexemes'))
ppc_lex <- group_ppc(final_model, dat, 'lex_main')
ppc_lex
save_book_figure(plot_ppc(ppc_lex), paste0('check_', TAG, '_ppc_lexemes'), height = 7)
