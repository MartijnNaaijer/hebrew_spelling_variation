################################################################################
# infc_qal_triliteral/analysis.R
#
# Dataset:  infc_qal_triliteral.csv - qal infinitive construct of triliteral
#           verbs in the MT and the Dead Sea Scrolls (no SP forms).
# Outcome:  has_vowel_letter (1 = full spelling, e.g. >MWR; 0 = defective, >MR).
# Questions:
#   1. Do the QSP and non-QSP scrolls spell the infinitive construct more fully
#      than the MT?
#   2. Within the MT: do the groups of books differ (Pentateuch, Former
#      Prophets, LBH, other books)?
#   3. Does the formula le'mor (>MR[, half of the data) behave differently?
#
# Status (2026-10-17): refit approved (TODO section 13 items 6-10) with MT
# Pentateuch as reference level and new file prefix infc2_; final model M2
# (section 3f). The result comments in 3f and 4b2 are updated to the refit
# (infc2_*, run of 2026-10-18); the old results are kept below them.
#
# Started from ../../trilit_infc_cleaned.R. Dropped from the old analysis:
#   - prefix models: 95% of the forms have a prefix (mostly L), so has_prefix
#     hardly varies; prefixes are shown descriptively.
#   - suffix: only 3 forms with a suffix.
#   - mosaic plots of gutturals: replaced by one book figure (2d).
#
# CHANGES 2026-10-17 (harmonisation of all verb forms, ../TODO.md section 13):
#   - Bayes factors dropped (author, 2026-10-14/17): RUN_BAYES_FACTORS and the
#     Bayes factor section removed; table_infc_bayes_factors.csv is stale.
#   - Prior sensitivity of M2 (sd 1.5 and 4) from the stored refits
#     infc_M2_prior1.5/prior4 (fitted 2026-10-09 for the Bayes factors); shown
#     in the robustness figure.
#   - Effects with the shared helpers of functions.R: median, 66% and 95%
#     quantile intervals (was HDI) and pd.
#   - Corpus-group effects shown against the MT Pentateuch (computed from the
#     draws; the model's reference level stays MT other books until the
#     refit, TODO section 13 item 6). Robustness figure as in ptca: one panel
#     per corpus group, one row per variant.
#   - New figure/table fig_infc_effects_not_in_final_model (guttural from M3;
#     the book's split of the non-QSP scrolls from n1).
#   - Local copies of shares_by(), plot_shares() and plot_ppc() removed (the
#     same functions are in functions.R).
#
# CHANGES 2026-10-17 (refit; ../TODO.md section 13 items 6-10, approved by
# the author 2026-10-17):
#   - Reference level of corpus_group: MT Pentateuch (was MT other books), as
#     in every verb form. Not only a reparametrisation: the MT Pentateuch is
#     almost always defective, so its level rests partly on the prior.
#   - New file prefix infc2_ for all model and k-fold files (models, prior
#     only, robustness, prior sensitivity); the old infc_* fits stay on disk,
#     unused.
#   - Drop-one k-fold table for M2 (M2 without corpus_group = M0):
#     table_infc_kfold_drop_one.csv. Prior sensitivity of M2 (sd 1.5 and 4)
#     refitted with the new reference level.
#   - Result of the refit (2026-10-18): the contrasts with the MT Pentateuch
#     shrank (QSP 10.8 -> 8.4, non-QSP 4.0 -> 1.6); only QSP and MT LBH stay
#     credible; the same M2 with MT other books as reference predicted +51.6
#     elpd (SE 3.9) better. Accepted by the author with this caveat. Caption
#     of fig_infc_effects_not_in_final_model updated (the old n1 vs M2 remark
#     no longer holds).
#   - Sampler: warmup 1000, iter 3000 (fit_model() default since 2026-10-17;
#     the old fits used 2000/6000).
#
# CHANGES 2026-10-19 (book figures for §9.4, BOOK_CHANGES_9.4.md):
#   - Charis and Hebrew in SBL Hebrew (heb_md()): אמר instead of "le'mor
#     (>MR[)", ר in the guttural labels; 'MT Other' instead of 'MT other
#     books' (labels only).
#   - New figures for the book: fig_infc_gutturals_2nd/_3rd/_either (MT
#     without אמר; Figs. 9.23-9.25) and fig_infc_random_qsp / _lbh (random
#     intercepts of M2 for the QSP documents and the MT LBH books; Figs.
#     9.28-9.29), with tables table_fig_infc_random_*.csv.
#   - Note of fig_infc_predicted on two lines.
#   - Suffix (3 forms) and prefix (95% of the forms) still cannot be modelled
#     (TODO section 13 item 9).
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
ANALYSIS_DIR <- CH09_DIR
VERB_FORM <- 'infc_qal_triliteral'
IMAGE_FOLDER <- file.path(ANALYSIS_DIR, VERB_FORM, 'figures')

source(file.path(SHARED_DIR, 'config.R'))
source(file.path(SHARED_DIR, 'functions.R'))

DATASET <- 'infc_qal_triliteral.csv'

GUTTURALS <- c('>', '<', 'X', 'H', 'R')
GUTTURAL_LABEL <- paste0('Guttural or ', heb_md('ר'), ' as 2nd or 3rd radical')

# ALLOW_FIT = FALSE: only load stored results; stop instead of fitting.
ALLOW_FIT <- FALSE  # all models fitted (runs of 2026-10-17/18, TODO section 13 items 6-10); set TRUE only after approval
options(analysis_verbs.allow_fit = ALLOW_FIT)
RUN_KFOLD <- TRUE


# ==== 1. DATA IMPORT AND PREPARATION ====

dat <- import_bib_data(DATA_FOLDER, DATASET) |>
  remove_ketiv_qere() |>
  add_col_has_suffix() |>
  split_isaiah_scroll() |>
  make_book2_column() |>
  make_scr_book2_column() |>
  make_law_phase_column(LAW_BOOKS, EBH_BOOKS, LBH_BOOKS) |>
  make_law_phase2_column(LAW_BOOKS, EBH_BOOKS, LBH_BOOKS, QSP_SCROLLS, law_phase2_levels) |>
  make_law_phase3_column(QSP_SCROLLS, law_phase3_levels) |>
  make_factor_columns(factor_columns) |>
  droplevels()

# ---- 1a. Predictors ----

# Corpus: MT, non-QSP scrolls, QSP scrolls (MT is the reference level).
dat$corpus <- factor(case_when(dat$scroll == 'MT' ~ 'MT',
                               dat$scroll %in% QSP_SCROLLS ~ 'QSP',
                               TRUE ~ 'Non-QSP'),
                     levels = c('MT', 'Non-QSP', 'QSP'))

# Group of books (for MT and scrolls alike): Pentateuch, Former Prophets, LBH, Other.
dat$book_group <- factor(case_when(dat$book %in% LAW_BOOKS ~ 'Pentateuch',
                                   dat$book %in% EBH_BOOKS ~ 'Former Prophets',
                                   dat$book %in% LBH_BOOKS ~ 'LBH',
                                   TRUE ~ 'Other'),
                         levels = c('Pentateuch', 'Former Prophets', 'LBH', 'Other'))

# Corpus group (6 levels): the MT split by group of books, the scrolls as one
# group per corpus. In the MT the group of books matters (Pentateuch 1% full,
# LBH 27%); in the scrolls it hardly does (non-QSP Pentateuch 20%, other books
# 21%; QSP 97% / 86%), so the groups of books are not carried over to the
# scrolls (author, 2026-10-08). Reference level: MT Pentateuch, as in every
# verb form (author, 2026-10-15; until 2026-10-17 it was MT other books).
dat$corpus_group <- factor(case_when(dat$corpus == 'MT' & dat$book_group == 'Other' ~ 'MT other books',
                                     dat$corpus == 'MT' ~ paste('MT', dat$book_group),
                                     TRUE ~ as.character(dat$corpus)),
                           levels = c('MT Pentateuch', 'MT Former Prophets', 'MT LBH',
                                      'MT other books', 'Non-QSP', 'QSP'))
stopifnot(levels(dat$corpus_group)[1] == 'MT Pentateuch')

# le'mor: the infinitive construct of >MR[ (1111 of 2186 forms).
dat$amr <- factor(as.numeric(dat$lex == '>MR['))

# Verb classes and gutturals
dat$ay_ay  <- factor(as.numeric(substr(dat$lex, 2, 2) == substr(dat$lex, 3, 3)))
dat$i_nun  <- factor(as.numeric(substr(dat$lex, 1, 1) == 'N'))
dat$iii_alef <- factor(as.numeric(substr(dat$lex, 3, 3) == '>'))
dat$guttural_2_or_3 <- factor(as.numeric(substr(dat$lex, 2, 2) %in% GUTTURALS |
                                           substr(dat$lex, 3, 3) %in% GUTTURALS))

# Robustness: the two halves of 1QIsaa separate from the other QSP scrolls.
dat$corpus_isa <- factor(case_when(dat$scroll == '1QisaaI' ~ '1QIsaa I',
                                   dat$scroll == '1QisaaII' ~ '1QIsaa II',
                                   TRUE ~ as.character(dat$corpus)),
                         levels = c('MT', 'Non-QSP', 'QSP', '1QIsaa I', '1QIsaa II'))

dat$corpus_group_isa <- factor(case_when(dat$scroll == '1QisaaI' ~ '1QIsaa I',
                                         dat$scroll == '1QisaaII' ~ '1QIsaa II',
                                         TRUE ~ as.character(dat$corpus_group)),
                               levels = c(levels(dat$corpus_group), '1QIsaa I', '1QIsaa II'))

# Passage (book, chapter, verse, lexeme), to find parallel forms.
dat$passage <- paste(dat$book, dat$chapter, dat$verse, dat$lex)

dat_no_amr <- dat |> filter(amr == 0) |> droplevels()

dim(dat)
table(dat$corpus, dat$has_vowel_letter)
table(dat$book_group, dat$corpus)
table(dat$corpus_group, dat$has_vowel_letter)
table(dat$amr, dat$corpus)
# Suffix and prefix are not modelled (TODO section 13 item 9: has_suffix and
# has_prefix are the shared predictors where they can be estimated): only 3
# forms have a suffix, and 95% of the forms have a prefix.
table(dat$has_suffix)    # 3 forms with a suffix: not modelled
table(dat$prefix)        # mostly L: has_prefix hardly varies


# ==== 2. EXPLORATORY ANALYSIS ====

# shares_by() and plot_shares() (functions.R): share of full spellings (95%
# interval) per row, with n at the right.

# ---- 2a. Groups of books, with and without le'mor ----
# le'mor is almost always defective in the MT (3 of 946 full) but always full
# in the QSP scrolls (51 of 51); it dominates the MT shares.

amr_label <- function(amr) factor(if_else(amr == 1, heb_md('אמר'), 'Other verbs'),
                                  levels = c('Other verbs', heb_md('אמר')))

groups_amr <- shares_by(dat, law_phase3, amr) |>
  filter(law_phase3 != 'Non-QSP LBH') |>          # 2 forms
  mutate(row = fct_rev(droplevels(law_phase3)), lexeme = amr_label(amr))
groups_amr

p <- plot_shares(groups_amr, colour_var = 'lexeme', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE)) +
  labs(caption = 'Non-QSP LBH (2 forms) not shown.') +
  markdown_legend()
p
save_book_figure(p, 'fig_infc_groups', height = 12)

# ---- 2b. QSP scrolls and the two halves of 1QIsaa ----

isaiah <- shares_by(filter(dat, book2 == 'Isaiah' &
                              corpus_isa %in% c('MT', '1QIsaa I', '1QIsaa II')), corpus_isa) |>
  mutate(row = factor(if_else(corpus_isa == 'MT', 'MT Isaiah', as.character(corpus_isa))))
other_qsp <- shares_by(filter(dat, corpus_isa == 'QSP'), corpus_isa) |>
  mutate(row = 'Other QSP scrolls')
qsp_rows <- bind_rows(isaiah, other_qsp) |>
  mutate(row = factor(row, levels = rev(c('MT Isaiah', '1QIsaa I', '1QIsaa II',
                                          'Other QSP scrolls'))))
qsp_rows

p <- plot_shares(qsp_rows)
p
save_book_figure(p, 'fig_infc_qsp_isaiah', height = 6)

# ---- 2c. Parallel passages: the same form in the MT and in a scroll ----

# Pairs the n-th scroll form with the n-th MT form of the same lexeme in the
# same verse (parallel_forms() in functions.R).
parallel_table <- parallel_forms(dat, occ = raw_occurrences('infc_qal')) |>  # raw-text pairing, 2026-11-05
  select(passage, scroll, corpus, lex, g_cons, mt_g_cons, has_vowel_letter, mt_full, pattern)
parallel_table |> count(corpus, pattern)
write_csv(parallel_table, file.path(IMAGE_FOLDER, 'table_infc_parallel_passages.csv'))

p <- parallel_table |>
  mutate(corpus = droplevels(corpus)) |>
  count(corpus, pattern) |>
  complete(corpus, pattern, fill = list(n = 0)) |>
  mutate(pattern = factor(pattern, levels = c('MT fuller', 'both defective',
                                              'both full', 'scroll fuller'))) |>
  ggplot(aes(y = pattern, x = n)) +
  geom_col(fill = BOOK_BLUE, width = 0.6) +
  geom_text(aes(label = n), hjust = -0.3, size = 3, colour = BOOK_INK_2) +
  facet_wrap(~ corpus) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.25))) +
  coord_cartesian(clip = 'off') +
  labs(x = 'Number of parallel forms', y = NULL) +
  theme_book() +
  theme(panel.grid.major.y = element_blank(),
        panel.spacing.x = unit(1.2, 'cm'))
p
save_book_figure(p, 'fig_infc_parallel_passages', height = 6)

# ---- 2d. Verb classes and gutturals (without le'mor) ----

classes <- bind_rows(
  shares_by(dat_no_amr) |> mutate(row = 'All verbs except le\'mor'),
  shares_by(filter(dat_no_amr, ay_ay == 1)) |> mutate(row = 'Ayin-ayin verbs'),
  shares_by(filter(dat_no_amr, i_nun == 1)) |> mutate(row = 'I-nun verbs'),
  shares_by(filter(dat_no_amr, iii_alef == 1)) |> mutate(row = 'III-alef verbs'),
  shares_by(filter(dat_no_amr, guttural_2_or_3 == 1)) |>
    mutate(row = 'Guttural (or R) as 2nd or 3rd radical'),
  shares_by(filter(dat_no_amr, guttural_2_or_3 == 0)) |>
    mutate(row = 'No guttural as 2nd or 3rd radical')
) |>
  mutate(row = factor(row, levels = rev(row)))
classes

p <- plot_shares(classes)
p
save_book_figure(p, 'fig_infc_explore_verb_classes', height = 7)

# Per corpus, because the corpora differ strongly in fullness
classes_corpus <- dat_no_amr |>
  mutate(guttural = factor(if_else(guttural_2_or_3 == 1, GUTTURAL_LABEL, 'Other verbs'),
                           levels = c('Other verbs', GUTTURAL_LABEL))) |>
  shares_by(corpus, guttural) |>
  mutate(row = fct_rev(corpus))
classes_corpus

p <- plot_shares(classes_corpus, colour_var = 'guttural', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE)) +
  labs(caption = paste0('Without ', heb_md('אמר'), '.')) +
  markdown_legend() + markdown_caption()
p
save_book_figure(p, 'fig_infc_explore_gutturals', height = 7)

# For the book (Figs. 9.23-9.25): MT without le'mor, guttural or R as 2nd
# radical, as 3rd radical, and in either position (Hornkohl's observation,
# tested against the base rate).
dat_mt_no_amr <- filter(dat_no_amr, corpus == 'MT')
radical_specs <- list(
  `2nd` = substr(dat_mt_no_amr$lex, 2, 2) %in% GUTTURALS,
  `3rd` = substr(dat_mt_no_amr$lex, 3, 3) %in% GUTTURALS,
  either = dat_mt_no_amr$guttural_2_or_3 == 1)
radical_titles <- c(`2nd` = 'second radical', `3rd` = 'third radical',
                    either = 'second or third radical')
iwalk(radical_specs, function(is_gutt, position) {
  tab <- dat_mt_no_amr |>
    mutate(row = factor(if_else(is_gutt, paste0('Guttural or ', heb_md('ר'), ' as ',
                                                radical_titles[[position]]),
                                'Other verbs'))) |>
    shares_by(row) |>
    mutate(row = fct_rev(row))
  print(tab)
  p <- plot_shares(tab) +
    labs(caption = paste0('MT without ', heb_md('אמר'), '.')) +
    markdown_y() + markdown_caption()
  save_book_figure(p, paste0('fig_infc_gutturals_', position), height = 4.5)
})

# ---- 2e. Prefixes (descriptive) ----

prefixes <- dat |>
  mutate(prefix_type = factor(case_when(prefix == '' ~ 'No prefix',
                                        prefix %in% c('L', 'WL') ~ 'L / WL',
                                        prefix %in% c('B', 'WB') ~ 'B / WB',
                                        prefix %in% c('K', 'WK') ~ 'K / WK',
                                        TRUE ~ 'Other prefix'),
                              levels = c('L / WL', 'B / WB', 'K / WK',
                                         'Other prefix', 'No prefix'))) |>
  shares_by(prefix_type) |>
  mutate(row = fct_rev(prefix_type))
prefixes
write_csv(select(prefixes, -row), file.path(IMAGE_FOLDER, 'table_infc_prefixes.csv'))

# ---- 2f. Lexemes ----

dat |>
  group_by(lex) |>
  summarise(n = n(), share_full = mean(as.numeric(as.character(has_vowel_letter)))) |>
  arrange(-n) |>
  head(15)


# ==== 3. DATA MODELLING ====
#
# Decisions (author, 2026-10-08; ../TODO.md section 7):
#   - Random part nested: (1 | scr_book2/lex).
#   - le'mor (>MR[) stays in the data as an ordinary lexeme, without a separate
#     fixed effect; the nested random part gives it its own intercept in every
#     scroll-book. Checked in section 5 (le'mor vs other verbs per corpus) and
#     by a robustness fit without le'mor.
#   - Priors normal(0, 2.5) on intercept and coefficients, exponential(1) on
#     the SDs (the infa prior normal(0, 1.5) is too narrow here: MT Pentateuch
#     ~1% full, QSP ~88%, about 7 logits apart). Sensitivity: sd 1.5 and 4.
#   - Models: M0 null; M1 corpus; M2 corpus_group (MT split by group of
#     books, scrolls one group per corpus); M3 M2 + guttural; n1 = law_phase3
#     (old final model, also splits the non-QSP scrolls) for comparison.
#   - Prefix and suffix are not modelled (95% of the forms have a prefix;
#     suffixed infinitives are not in the dataset).
#   - Reference level MT Pentateuch; files infc2_* (refit 2026-10-17).

PRIOR_SD <- 2.5
priors <- book_priors(PRIOR_SD)
priors_null <- book_priors(PRIOR_SD, has_fixed = FALSE)

# ---- 3a. Prior predictive check ----

model_prior_only <- fit_model('infc2_M3_prior_only.rds',
                              has_vowel_letter ~ corpus_group + guttural_2_or_3 +
                                (1 | scr_book2/lex),
                              dat, priors, sample_prior = 'only')

prior_shares <- posterior_predict(model_prior_only, ndraws = 4000) |> rowMeans()
p <- tibble(share = prior_shares) |>
  ggplot(aes(x = share)) +
  geom_histogram(binwidth = 0.025, boundary = 0, fill = BOOK_GREY, colour = 'white',
                 linewidth = 0.3) +
  geom_vline(xintercept = mean(as.numeric(as.character(dat$has_vowel_letter))),
             colour = BOOK_BLUE, linewidth = 0.8) +
  scale_x_continuous(labels = scales::percent) +
  labs(x = 'Share of full spellings in a simulated dataset (prior only)',
       y = 'Number of simulations', caption = 'Blue line: observed share.') +
  theme_book()
p
save_book_figure(p, 'check_infc_prior_predictive', height = 8)
rm(model_prior_only); gc()

# ---- 3b. Candidate models ----
# Fitted once and stored; to save memory the models are not kept in memory
# together but loaded only when needed (see functions.R, memory-saving helpers).

model_specs <- list(
  M0 = has_vowel_letter ~ 1 + (1 | scr_book2/lex),
  M1 = has_vowel_letter ~ corpus + (1 | scr_book2/lex),
  M2 = has_vowel_letter ~ corpus_group + (1 | scr_book2/lex),
  M3 = has_vowel_letter ~ corpus_group + guttural_2_or_3 + (1 | scr_book2/lex),
  n1 = has_vowel_letter ~ law_phase3 + (1 | scr_book2/lex)
)
model_file <- function(id, scale_b = PRIOR_SD) {
  if (scale_b == PRIOR_SD) paste0('infc2_', id, '.rds')
  else paste0('infc2_', id, '_prior', scale_b, '.rds')
}

ensure_model <- function(id, scale_b = PRIOR_SD) {
  if (!file.exists(file.path(MODEL_FOLDER, model_file(id, scale_b)))) {
    fit_model(model_file(id, scale_b), model_specs[[id]], dat,
              book_priors(scale_b, has_fixed = id != 'M0'))
    gc()
  }
  invisible(model_file(id, scale_b))
}

walk(names(model_specs), ensure_model)

# Fixed effects of all candidate models (one model in memory at a time)
for (id in names(model_specs)) {
  cat('\n====', id, '====\n')
  m <- load_model(model_file(id))
  print(fixef(m))
  rm(m); gc()
}

# ---- 3c. Grouped k-fold cross-validation ----
# 5 folds; every scroll-book is left out as a whole. (5 instead of 10 folds to
# keep the run time and memory use manageable with 2186 forms.)

set.seed(2026)
folds <- loo::kfold_split_grouped(K = 5, x = as.character(dat$scr_book2))

if (RUN_KFOLD) {
  kfolds <- map(set_names(names(model_specs)),
                \(id) kfold_lazy(model_file(id), paste0('infc2_', id, '_k5'), folds))
  kfold_comparison <- loo_compare(kfolds)
  print(kfold_comparison)
  kfold_table <- as.data.frame(kfold_comparison) |>
    rownames_to_column('model') |>
    select(model, elpd_diff, se_diff, elpd_kfold, se_elpd_kfold)
  write_csv(kfold_table, file.path(IMAGE_FOLDER, 'table_infc_kfold.csv'))

  # Drop-one comparison for the final model (rule 4): M2 has one effect, and
  # M2 without corpus_group is M0. elpd_diff = reduced - final (negative =
  # the effect improves the predictions for new books).
  drop_one <- drop_one_kfold_table(kfolds, 'M2', c('corpus group' = 'M0'))
  print(drop_one)
  write_csv(drop_one, file.path(IMAGE_FOLDER, 'table_infc_kfold_drop_one.csv'))
}

# ---- 3d. Prior sensitivity of the final model M2 ----
# M2 with priors normal(0, 1.5) and normal(0, 4) on the coefficients (refit
# 2026-10-17 with the new reference level); read in section 4d.

walk(c(1.5, 4), \(scale_b) ensure_model('M2', scale_b))

# ---- 3e. Robustness ----
# Fitted and stored here; their coefficients are read in section 4d.

robustness_specs <- list(
  isa_split = list(file = 'infc2_M2_1QIsaa_split.rds',
                   formula = has_vowel_letter ~ corpus_group_isa + (1 | scr_book2/lex),
                   data = dat),
  no_1qisaa = list(file = 'infc2_M2_no_1QIsaa.rds', formula = model_specs$M2,
                   data = filter(dat, !scroll %in% c('1QisaaI', '1QisaaII')) |> droplevels()),
  no_amr    = list(file = 'infc2_M2_no_amr.rds', formula = model_specs$M2,
                   data = dat_no_amr)
)
walk(robustness_specs, function(r) {
  if (!file.exists(file.path(MODEL_FOLDER, r$file))) {
    fit_model(r$file, r$formula, r$data, priors)
    gc()
  }
})

# ---- 3f. Final model: M2 (corpus_group) ----
# Results of the refit (infc2_*, reference MT Pentateuch, warmup 1000 / iter
# 3000; run of 2026-10-18):
#   5-fold grouped cross-validation (elpd difference to M2, SE):
#     M3 (+ guttural) -10.0 (1.1); n1 (law_phase3) -12.0 (1.9);
#     M1 (corpus) -45.1 (4.8); M0 -325.3 (17.2) (= drop-one for corpus group).
#   M2 still predicts clearly best, but n1 and M1 are much closer than in the
#   old fits: the k-fold changed with the reference level, because the MT
#   Pentateuch (almost all defective) is now the intercept and rests on the
#   prior.
#   Effects vs MT Pentateuch (log-odds, 95% quantile interval, pd):
#     QSP 8.36 (6.19 to 10.51), 1.00; MT LBH 3.18 (0.73 to 5.43), 0.993;
#     non-QSP 1.55 (-0.67 to 3.37), 0.92; MT other books 1.49 (-0.65 to
#     3.38), 0.92; MT Former Prophets 0.89 (-1.60 to 3.05), 0.77.
#     (Old fits, vs MT Pentateuch from the draws: QSP 10.8, LBH 5.8, non-QSP
#     4.0, other books 4.2, Former Prophets 3.4, all credible.)
#   Robustness (vs MT Pentateuch): QSP without 1QIsaa 8.63; without le'mor
#     6.69 (4.92 to 8.66); 1QIsaa I 2.71 (-0.98 to 6.14), 1QIsaa II 5.00
#     (0.91 to 8.82), other QSP scrolls 7.65 (5.31 to 10.05). Non-QSP
#     without le'mor 2.30 (0.51 to 3.86). Prior sd 1.5: only QSP credible;
#     sd 4: all groups except the Former Prophets credible.
# With MT Pentateuch as reference only QSP and MT LBH are credibly fuller
# than the MT Pentateuch; non-QSP, MT other books and Former Prophets are no
# longer credible. The author accepted this, with the prior dependence as a
# caveat in REPORT.md (2026-10-18).
# Old results (infc_*, reference MT other books, run of 2026-10-09):
#   5-fold grouped cross-validation (elpd difference to M2, SE):
#     M3 (+ guttural) -7.1 (1.0); n1 (law_phase3) -64.1 (4.4);
#     M1 (corpus) -95.9 (6.5); M0 -376.2 (17.8).
#   M2 predicts clearly best. Splitting the MT by group of books is essential
#   (M1 much worse); splitting the non-QSP scrolls by group of books as well
#   (n1) makes the predictions clearly worse; gutturals do not help (M3).
#   Bayes factors dropped (author, 2026-10-14/17).
#   Robustness (log-odds vs MT other books, 95% interval):
#     QSP all data 6.7 (4.9 to 8.6); without 1QIsaa 7.0; without le'mor 4.7
#     (3.2 to 6.4: le'mor, 51 of 51 full in QSP, makes the QSP effect larger,
#     but it is large without it too); 1QIsaa I 2.6 (-0.2 to 5.4), 1QIsaa II
#     5.4 (2.1 to 8.6), other QSP scrolls 6.7 (4.7 to 8.8).
#     Non-QSP all data -0.1 (-1.4 to 1.1), without le'mor 0.2 (-0.9 to 1.3).
# Author's review (2026-10-09): M2 accepted as final model.
final_model <- load_model(model_file('M2'))
summary(final_model)


# ==== 4. DATA VISUALISATION ====

# ---- 4a. Table of fixed effects ----

fixed_table <- make_fixed_effects_table(final_model)
fixed_table
write_csv(rownames_to_column(fixed_table, 'parameter'),
          file.path(IMAGE_FOLDER, 'table_infc_fixed_effects.csv'))

# ---- 4b. Effects (odds ratios) ----
# The reference level is the MT Pentateuch (refit 2026-10-17), so the
# corpus-group coefficients are the effects vs the MT Pentateuch.
# corpus_vs_pentateuch() also works for a fit with another reference level:
# b_g - b_MTPentateuch, where the coefficient of the reference level is 0.

CORPUS_COEF <- c('MT Former Prophets' = 'MTFormerProphets', 'MT LBH' = 'MTLBH',
                 'MT Other' = 'MTotherbooks', 'Non-QSP scrolls' = 'NonMQSP',
                 'QSP scrolls' = 'QSP', '1QIsaa I' = '1QIsaaI', '1QIsaa II' = '1QIsaaII')

# Draws of every corpus group vs the MT Pentateuch (prefix: the coefficient
# name of the corpus factor, b_corpus_group or b_corpus_group_isa). A group
# without a coefficient is the reference level (0); 1QIsaa I/II only exist
# in the 1QIsaa split fit.
corpus_vs_pentateuch <- function(model, prefix = 'b_corpus_group') {
  d <- as_draws_df(model)
  levels_in_fit <- levels(model$data[[sub('^b_', '', prefix)]])
  coef_or_0 <- function(name) if (name %in% names(d)) d[[name]] else 0
  pentateuch <- coef_or_0(paste0(prefix, 'MTPentateuch'))
  imap_dfr(CORPUS_COEF, function(coef, group) {
    level <- c(MTFormerProphets = 'MT Former Prophets', MTLBH = 'MT LBH',
               MTotherbooks = 'MT other books', NonMQSP = 'Non-QSP', QSP = 'QSP',
               `1QIsaaI` = '1QIsaa I', `1QIsaaII` = '1QIsaa II')[[coef]]
    if (level %in% levels_in_fit)
      tibble(group = group, value = coef_or_0(paste0(prefix, coef)) - pentateuch)
  })
}

# Odds ratios up to about 10^6 (QSP vs MT Pentateuch)
or_breaks <- 10^(-1:7)
or_labels <- c('0.1', '1', '10', '100', '1,000', '10,000', '100,000', '1 million', '10 million')
or_x <- 'Odds ratio for full spelling vs MT Pentateuch (log scale)'

effects <- corpus_vs_pentateuch(final_model) |>
  summarise_effects(group) |>
  mutate(group = factor(group, levels = rev(names(CORPUS_COEF)))) |>
  arrange(desc(group))
effects
write_csv(effects, file.path(IMAGE_FOLDER, 'table_infc_effects.csv'))

p <- plot_or(effects, group, breaks = or_breaks, labels = or_labels) +
  labs(x = or_x)
p
save_book_figure(p, 'fig_infc_effects', height = 7)

# ---- 4b2. Effects not in the final model ----
# No credible gain (rule 1; k-fold M3 -10.0, n1 -12.0 vs M2, refit): a
# guttural or R as 2nd or 3rd radical (M3), and the book's split of the
# non-QSP scrolls by group of books (n1, law_phase3; reference MT Pentateuch).
# Caption: since the refit (2026-10-18) n1 and M2 estimate the MT groups
# alike (MT other books vs MT Pentateuch 1.23 and 1.49), so the old remark
# about n1 is dropped.

not_in_final <- effects_not_in_final_model(tribble(
  ~label,                                                  ~file,            ~parameter,
  'Guttural or R as 2nd/3rd radical (M3, vs none)',        model_file('M3'), 'b_guttural_2_or_31',
  'Non-QSP Pentateuch vs MT Pentateuch (n1)',              model_file('n1'), 'b_law_phase3NonMQSPPentateuch',
  'Non-QSP Former Prophets vs MT Pentateuch (n1)',         model_file('n1'), 'b_law_phase3NonMQSPFormerProphets',
  'Non-QSP LBH vs MT Pentateuch (n1; 2 forms)',            model_file('n1'), 'b_law_phase3NonMQSPLBH',
  'Non-QSP other books vs MT Pentateuch (n1)',             model_file('n1'), 'b_law_phase3NonMQSPOther'
))
not_in_final
write_csv(not_in_final, file.path(IMAGE_FOLDER, 'table_infc_effects_not_in_final_model.csv'))
p <- plot_effects_not_in_final_model(
  not_in_final, or_breaks, or_labels,
  caption = paste0('Not in the final model M2 (comparison models M3 and n1).\n',
                   'n1 also splits the non-QSP scrolls by group of books; it predicts worse.\n',
                   OR_CAPTION))
p
save_book_figure(p, 'fig_infc_effects_not_in_final_model', height = 7)

# ---- 4c. Predicted probability of full spelling ----
# Population level (re_formula = NA): a typical scroll-book and lexeme, no
# guttural.

newdata <- tibble(condition = c('MT Pentateuch', 'MT Former Prophets', 'MT LBH',
                                'MT Other', 'Non-QSP scrolls', 'QSP scrolls'),
                  corpus_group = c('MT Pentateuch', 'MT Former Prophets', 'MT LBH',
                                   'MT other books', 'Non-QSP', 'QSP')) |>
  mutate(corpus_group = factor(corpus_group, levels = levels(dat$corpus_group)),
         guttural_2_or_3 = factor('0', levels = levels(dat$guttural_2_or_3)))

# Equal-tailed intervals: for probabilities close to 0 or 1 the HDI can split
# into two pieces.
predicted <- newdata |>
  add_epred_draws(final_model, re_formula = NA) |>
  group_by(condition) |>
  median_qi(.epred, .width = c(0.66, 0.95)) |>
  mutate(condition = factor(condition, levels = rev(newdata$condition)))
predicted
write_csv(predicted, file.path(IMAGE_FOLDER, 'table_infc_predicted.csv'))

p <- predicted |>
  ggplot(aes(y = condition, x = .epred, xmin = .lower, xmax = .upper)) +
  geom_pointinterval(colour = BOOK_BLUE, point_size = 2.5,
                     interval_size_range = c(0.8, 2)) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25),
                     labels = scales::percent) +
  labs(x = 'Predicted probability of full spelling', y = NULL,
       caption = paste(OR_CAPTION, 'Typical book and lexeme.', sep = '\n')) +
  theme_book()
p
save_book_figure(p, 'fig_infc_predicted', height = 7)

# ---- 4d. Robustness and prior sensitivity ----
# Every corpus group vs the MT Pentateuch in M2, without 1QIsaa, without
# le'mor, with the halves of 1QIsaa as separate groups (there 'QSP scrolls'
# are the other QSP scrolls), and in M2 with priors sd 1.5 and 4.

robust_specs <- list('M2 (final)'        = list(file = model_file('M2'), prefix = 'b_corpus_group'),
                     'M2 without 1QIsaa' = list(file = 'infc2_M2_no_1QIsaa.rds', prefix = 'b_corpus_group'),
                     "M2 without le'mor" = list(file = 'infc2_M2_no_amr.rds', prefix = 'b_corpus_group'),
                     'M2, 1QIsaa split'  = list(file = 'infc2_M2_1QIsaa_split.rds',
                                                prefix = 'b_corpus_group_isa'),
                     'M2, prior sd 1.5'  = list(file = model_file('M2', 1.5), prefix = 'b_corpus_group'),
                     'M2, prior sd 4'    = list(file = model_file('M2', 4), prefix = 'b_corpus_group'))
robustness <- imap_dfr(robust_specs, function(r, variant) {
  m <- if (r$file == model_file('M2')) final_model else load_model(r$file)
  if (!grepl('without', variant) && nrow(m$data) != nrow(dat)) {
    warning(r$file, ' has ', nrow(m$data), ' rows, the data ', nrow(dat), call. = FALSE)
  }
  out <- corpus_vs_pentateuch(m, r$prefix) |>
    summarise_effects(group) |>
    mutate(variant = variant)
  if (r$file != model_file('M2')) { rm(m); gc() }
  out
}) |>
  mutate(group = factor(group, levels = names(CORPUS_COEF)),
         variant = factor(variant, levels = rev(names(robust_specs)))) |>
  arrange(group, desc(variant))
robustness
write_csv(robustness, file.path(IMAGE_FOLDER, 'table_infc_robustness.csv'))

p <- plot_or(robustness, variant, breaks = 10^c(0, 2, 4, 6),
             labels = c('1', '100', '10,000', '1 million')) +
  facet_wrap(~ group, ncol = 2, scales = 'free_y') +
  labs(x = or_x,
       caption = paste0("1QIsaa split: 'QSP scrolls' are the other QSP scrolls.\n", OR_CAPTION))
p
save_book_figure(p, 'fig_infc_robustness', height = 18)

# ---- 4e. Random intercepts of the books (check) ----

p <- plot_random_intercepts(final_model, 'scr_book2', text_size = 5) + theme_book()
save_book_figure(p, 'check_infc_random_books', height = 24)

# ---- 4f. Random intercepts of the QSP documents and the MT LBH books ----
# For the book (Figs. 9.28 and 9.29): the document-level (scr_book2)
# intercepts of the final model, median with 66% and 95% interval.

doc_label <- function(x) {
  x |>
    str_replace('^1QisaaI_Isaiah$', '1QIsa<sup>a</sup> Part I') |>
    str_replace('^1QisaaII_Isaiah$', '1QIsa<sup>a</sup> Part II') |>
    str_replace('^MT_', '') |>
    str_replace('_', ' ')
}
book_ranef <- ranef(final_model, robust = TRUE, probs = c(0.025, 0.17, 0.83, 0.975))$scr_book2[, , 'Intercept'] |>
  as.data.frame() |>
  rownames_to_column('doc')
plot_doc_ranef <- function(docs, name, height) {
  tab <- book_ranef |>
    filter(doc %in% docs) |>
    mutate(label = fct_reorder(doc_label(doc), Estimate))
  write_csv(mutate(tab, label = strip_md(label)), file.path(IMAGE_FOLDER, paste0('table_', name, '.csv')))
  p <- ggplot(tab, aes(y = label, x = Estimate)) +
    geom_vline(xintercept = 0, colour = BOOK_GREY) +
    geom_linerange(aes(xmin = Q2.5, xmax = Q97.5), linewidth = 0.6, colour = BOOK_BLUE) +
    geom_linerange(aes(xmin = Q17, xmax = Q83), linewidth = 1.6, colour = BOOK_BLUE) +
    geom_point(size = 2.3, colour = BOOK_BLUE) +
    labs(x = 'Document-level random intercept (logit scale)', y = NULL, caption = OR_CAPTION) +
    theme_book() +
    markdown_y()
  save_book_figure(p, name, height = height)
}
plot_doc_ranef(unique(as.character(dat$scr_book2[dat$corpus == 'QSP'])), 'fig_infc_random_qsp', 13)
plot_doc_ranef(unique(as.character(dat$scr_book2[dat$corpus == 'MT' & dat$book_group == 'LBH'])),
               'fig_infc_random_lbh', 5)


# ==== 5. MODEL VERIFICATION ====

# Convergence, trace and density plots, posterior predictive checks, LOO (for
# completeness; unreliable with the nested structure) and Bayes R2. The
# in-sample classification it prints is optimistic.
verification <- verify_model(final_model, IMAGE_FOLDER, 'check_infc')

# Observed vs predicted share of full spellings (plot_ppc() in functions.R)
# per group of books and, for
# le'mor (which has no fixed effect), per corpus for le'mor and other verbs.
dat$corpus_amr <- factor(paste(dat$corpus, if_else(dat$amr == 1, "le'mor", 'other verbs')),
                         levels = c("MT other verbs", "MT le'mor",
                                    "Non-QSP other verbs", "Non-QSP le'mor",
                                    "QSP other verbs", "QSP le'mor"))

ppc_groups <- group_ppc(final_model, dat, 'law_phase3')
ppc_groups
save_book_figure(plot_ppc(ppc_groups), 'check_infc_ppc_groups', height = 8)

ppc_amr <- group_ppc(final_model, dat, 'corpus_amr')
ppc_amr
save_book_figure(plot_ppc(ppc_amr), 'check_infc_ppc_lemor', height = 7)
