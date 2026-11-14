################################################################################
# infa_qal/analysis.R
#
# Dataset:  infa_qal.csv - qal infinitive absolute in the MT and the Dead Sea
#           Scrolls (no SP forms in this dataset).
# Outcome:  has_vowel_letter (1 = full spelling, 0 = defective).
# Questions:
#   1. Do the QSP scrolls (and the non-QSP scrolls) spell the qal infinitive
#      absolute more fully than the MT?
#   2. Do the late books (LBH) spell more fully?
#   3. Do ayin-ayin (ע-ע) verbs and forms with a prefix behave differently?
#
# Design decisions (2026-10-08, see ../TODO.md and analysis/README.md; priors,
# folds and model set replaced on 2026-10-17, see CHANGES 2026-10-17):
#   - Random part always nested: (1 | scr_book2/lex).
#   - Weakly informative priors: normal(0, 1.5) on intercept and coefficients,
#     exponential(1) on the random-intercept SDs (the old normal(0, 5) priors
#     put most prior mass on probabilities near 0 and 1 and made Bayes factors
#     punish every extra coefficient). Checked with a prior predictive check.
#   - A small set of models fixed in advance (M0-M4), plus the old final model
#     infa7 (is_qsp + ay_ay) refitted with the same priors for comparison.
#   - Model comparison by grouped k-fold cross-validation (whole scroll-books
#     left out). LOO is unreliable here: most book:lexeme groups contain one form.
#     Bayes factors dropped (author, 2026-10-14/17).
#   - Robustness: QSP without 1QIsaa; 1QIsaa I, 1QIsaa II and the other QSP
#     scrolls as separate groups.
#   - Parallel passages (same form in MT and a scroll) are shown descriptively;
#     a passage effect would break the nested random structure.
#   - In-sample accuracy is not used as a quality measure (inflated by the
#     book:lexeme intercepts); fit is checked per corpus group instead.
#
# CHANGES 2026-10-10:
#   - Final model M3 -> M3b (corpus + ayin-ayin): final models contain only
#     credible effects (analysis/README.md). New models M3b and A1 (for the k-fold
#     comparison without corpus); robustness and prior sensitivity on M3b.
#   - Intervals in the figures: median_qi instead of median_hdi (the HDI is
#     unstable for probabilities near 0 and 1; as in the other verb forms).
#   - New figure fig_infa_effects_not_in_final_model (LBH, prefix) and tables
#     table_infa_effects, table_infa_qsp_robustness, table_infa_kfold_final_model.
#   - Later the same day: final model M3b -> infa7 (QSP vs MT and non-QSP
#     together + ayin-ayin; author). infa7 predicts slightly better than M3b
#     (k-fold 1.2, SE 0.6); the non-QSP coefficient of M3b is about 0. New
#     model Q1 (infa7 without ayin-ayin) for the k-fold comparison; robustness
#     fits on infa7; prior sensitivity from the stored infa7 fits with sd 1
#     and 2.5. The non-QSP effect (M3b) is reported in section 4f (4e since 2026-10-17).
#
# CHANGES 2026-10-17 (harmonisation of all verb forms, ../TODO.md section 13):
#   - Bayes factors removed (old section 3d and its prior refits of M0-M4;
#     the stored fits and table_infa_bayes_factors.csv are no longer used).
#     Sections 3e/3f renumbered 3d/3e.
#   - Effect tables and figures use the shared helpers of ../functions.R
#     (summarise_effects, plot_or, effects_not_in_final_model): median, 66%
#     and 95% quantile intervals and pd in every effect table; the tables are
#     now one row per effect (columns .lower/lower66/upper66/.upper). The
#     prior sensitivity table also has the 66% interval and pd.
#
# CHANGES 2026-10-17 (item 8 of ../TODO.md section 13, approved by the author):
#   - Aligned with the other verb forms: prior normal(0, 2.5) (was 1.5) with
#     sensitivity sd 1.5 and 4 (was 1 and 2.5); grouped 5-fold k-fold (was 10
#     folds); corpus_group (6 levels, MT Pentateuch as reference, non-QSP one
#     group) instead of corpus + LBH dummy.
#   - New model set M0 null, M1 corpus, M2 corpus_group, M3 M2 + ayin-ayin,
#     M4 M3 + prefix, plus M3b (corpus + ayin-ayin), infa7 (the book's final
#     model, is_qsp + ayin-ayin) and Q1 (is_qsp) for comparison. Provisional
#     final model M3 (FINAL_ID); the final model is chosen after the run.
#   - Drop-one k-fold, prior sensitivity and robustness (without 1QIsaa,
#     1QIsaa I/II separate) follow FINAL_ID. New files table_infa_kfold_drop_one,
#     table_infa_robustness and fig_infa_robustness replace
#     table_infa_kfold_final_model, table_infa_qsp_robustness,
#     table_infa_prior_sensitivity and fig_infa_qsp_robustness.
#   - Model files 'infa2_*' (sampler warmup 1000, iter 3000; ../functions.R);
#     the old 'infa_*' fits stay on disk, unused. The results of the new
#     run (2026-10-18) are recorded in section 3e and in REPORT.md. Final
#     model M3 (author, 2026-10-18).
#   - Book figures (2026-10-19): Charis as in the book (theme_book() in
#     ../functions.R); Hebrew labels in SBL Hebrew (heb_md(): ע״ע, פ״י, הלך
#     instead of Ayin-ayin, I-yod, HLK[); 'MT Other' instead of 'MT other
#     books' (labels only, the factor level is unchanged); no 'Final model M3'
#     in the notes; the note of fig_infa_predicted on two lines (it was cut
#     off).
#
# Model fits:  MODEL_FOLDER (config.R), files 'infa2_*.rds' (since 2026-10-17;
#              'infa_*.rds' before).
# Figures:     infa_qal/figures/fig_infa_*.png/.pdf (book), check_infa_* (checks).
#
# CHANGES 2026-11-10 (author: chapter 9 figures like chapter 8):
#   - The book figures by document group use corpus_group, with the non-QSP
#     scrolls as one group (column fig_group, labelled 'MT Other'), instead
#     of law_phase3 (non-QSP split by group of books), as the models and the
#     figures of chapter 8. The filters and captions for Non-QSP LBH are gone.
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
VERB_FORM <- 'infa_qal'
IMAGE_FOLDER <- file.path(ANALYSIS_DIR, VERB_FORM, 'figures')

source(file.path(SHARED_DIR, 'config.R'))
source(file.path(SHARED_DIR, 'functions.R'))

DATASET <- 'infa_qal.csv'

# Set to TRUE to (re)run the time-consuming steps when the fits are not stored
# yet: k-fold cross-validation (5 refits per model).
RUN_KFOLD <- TRUE

# ALLOW_FIT = FALSE: only load stored results; stop instead of fitting.
ALLOW_FIT <- FALSE  # all models fitted (runs of 2026-10-17/18, TODO section 13 items 6-10); set TRUE only after approval
options(analysis_verbs.allow_fit = ALLOW_FIT)


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

# ---- 1a. Data corrections (documented, by tf_id) ----
# 11Q5, 2 Sam 23:7, FRP[ written FRWPP: the waw is a vowel letter, but the
# form was coded as defective in the dataset.
corrections <- tribble(
  ~tf_id,   ~has_vowel_letter, ~reason,
  2086635,  1,                 'FRWPP (11Q5, 2 Sam 23:7): waw is a vowel letter'
)
for (i in seq_len(nrow(corrections))) {
  dat$has_vowel_letter[dat$tf_id == corrections$tf_id[i]] <- corrections$has_vowel_letter[i]
}

# ---- 1b. Predictors ----

# Corpus: MT, non-QSP scrolls, QSP scrolls (MT is the reference level).
dat$corpus <- factor(case_when(dat$scroll == 'MT' ~ 'MT',
                               dat$scroll %in% QSP_SCROLLS ~ 'QSP',
                               TRUE ~ 'Non-QSP'),
                     levels = c('MT', 'Non-QSP', 'QSP'))

# Late Biblical Hebrew books (descriptive; LBH is a level of corpus_group).
# In this dataset all LBH forms are MT forms.
dat$lbh <- factor(as.numeric(dat$book %in% LBH_BOOKS))

# Corpus group (6 levels), as in the other verb forms: the MT split by group of
# books, the scrolls one group per corpus (non-QSP is one group). Reference
# level: MT Pentateuch (author, 2026-10-15).
dat$book_group <- factor(case_when(dat$book %in% LAW_BOOKS ~ 'Pentateuch',
                                   dat$book %in% EBH_BOOKS ~ 'Former Prophets',
                                   dat$book %in% LBH_BOOKS ~ 'LBH',
                                   TRUE ~ 'Other'),
                         levels = c('Pentateuch', 'Former Prophets', 'LBH', 'Other'))
CORPUS_GROUPS <- c('MT Pentateuch', 'MT Former Prophets', 'MT LBH', 'MT other books',
                   'Non-QSP', 'QSP')
dat$corpus_group <- factor(case_when(dat$corpus == 'MT' & dat$book_group == 'Other' ~ 'MT other books',
                                     dat$corpus == 'MT' ~ paste('MT', dat$book_group),
                                     TRUE ~ as.character(dat$corpus)),
                           levels = CORPUS_GROUPS)
stopifnot(!anyNA(dat$corpus_group))

# Ayin-ayin verbs: second and third radical identical.
dat$ay_ay <- factor(as.numeric(substr(dat$lex, 2, 2) == substr(dat$lex, 3, 3)))

# I-yod verbs (original waw verbs; not the original yod verbs in YOD_VERBS),
# including HLK[. Descriptive only: the class is dominated by HLK[ (57 forms)
# and JD<[ (16 forms), which go in opposite directions.
dat$i_yod <- factor(as.numeric((substr(dat$lex, 1, 1) == 'J' & !(dat$lex %in% YOD_VERBS)) |
                                 dat$lex == 'HLK['))

# QSP vs all other forms (MT and non-QSP scrolls): the final model infa7.
dat$is_qsp <- factor(as.numeric(dat$corpus == 'QSP'))

# Robustness: the two halves of 1QIsaa separate from the other QSP scrolls,
# for each corpus coding (corpus_group, corpus, is_qsp).
dat$corpus_group_isa <- factor(case_when(dat$scroll == '1QisaaI' ~ '1QIsaa I',
                                         dat$scroll == '1QisaaII' ~ '1QIsaa II',
                                         TRUE ~ as.character(dat$corpus_group)),
                               levels = c(CORPUS_GROUPS, '1QIsaa I', '1QIsaa II'))
dat$corpus_isa <- factor(case_when(dat$scroll == '1QisaaI' ~ '1QIsaa I',
                                   dat$scroll == '1QisaaII' ~ '1QIsaa II',
                                   TRUE ~ as.character(dat$corpus)),
                         levels = c('MT', 'Non-QSP', 'QSP', '1QIsaa I', '1QIsaa II'))
# The same for infa7: reference MT and non-QSP scrolls together.
dat$qsp_isa <- factor(case_when(dat$scroll == '1QisaaI' ~ '1QIsaa I',
                                dat$scroll == '1QisaaII' ~ '1QIsaa II',
                                dat$corpus == 'QSP' ~ 'QSP',
                                TRUE ~ 'MT/Non-QSP'),
                      levels = c('MT/Non-QSP', 'QSP', '1QIsaa I', '1QIsaa II'))

# Passage (book, chapter, verse, lexeme), to find parallel forms.
dat$passage <- paste(dat$book, dat$chapter, dat$verse, dat$lex)

dat_no_1qisaa <- dat |> filter(!scroll %in% c('1QisaaI', '1QisaaII')) |> droplevels()

dim(dat)
table(dat$corpus, dat$has_vowel_letter)
table(dat$lbh, dat$corpus)
table(dat$corpus_group, dat$has_vowel_letter)
table(dat$ay_ay, dat$has_vowel_letter)
table(dat$has_prefix, dat$has_vowel_letter)
table(dat$has_suffix)   # no suffixes on the infinitive absolute in this dataset


# ==== 2. EXPLORATORY ANALYSIS ====

# Document groups of the book figures: corpus_group, the non-QSP scrolls as
# one group (author, 2026-11-10), labelled as in the book.
dat$fig_group <- fct_recode(dat$corpus_group, 'MT Other' = 'MT other books')

# ---- 2a. Groups of books and corpora ----

full_groups <- fullness_by_group(dat, 'fig_group')
full_groups

p <- full_groups |>
  mutate(corpus = case_when(str_starts(group, 'MT') ~ 'MT',
                            str_starts(group, 'Non-QSP') ~ 'Non-QSP',
                            TRUE ~ 'QSP'),
         corpus = factor(corpus, levels = c('MT', 'Non-QSP', 'QSP')),
         group = fct_rev(group)) |>
  ggplot(aes(y = group, x = mean, xmin = lower, xmax = upper, colour = corpus)) +
  geom_linerange(linewidth = 0.8) +
  geom_point(size = 2.5) +
  geom_text(aes(x = 1.02, label = paste0('n = ', n)), hjust = 0, size = 3,
            colour = BOOK_INK_2) +
  scale_colour_manual(values = BOOK_CATEGORICAL) +
  scale_x_continuous(limits = c(0, 1.15), breaks = seq(0, 1, 0.25),
                     labels = scales::percent) +
  labs(x = 'Full spelling (share of forms, 95% interval)', y = NULL) +
  theme_book()
p
save_book_figure(p, 'fig_infa_groups', height = 7)

# ---- 2b. Ayin-ayin verbs, I-yod verbs and prefix ----

fullness_by_group(dat, 'ay_ay')
fullness_by_group(dat, 'i_yod')
fullness_by_group(dat, 'has_prefix')

# Verb classes (all corpora together)
verb_classes <- bind_rows(
  fullness_by_group(filter(dat, ay_ay == 0 & i_yod == 0), 'corpus') |>
    summarise(full = sum(full), n = sum(n)) |> mutate(class = 'Other verbs'),
  fullness_by_group(filter(dat, ay_ay == 1), 'ay_ay') |>
    select(full, n) |> mutate(class = paste(heb_md('ע״ע'), 'verbs')),
  fullness_by_group(filter(dat, i_yod == 1 & lex != 'HLK['), 'i_yod') |>
    select(full, n) |> mutate(class = paste(heb_md('פ״י'), 'verbs without', heb_md('הלך'))),
  fullness_by_group(filter(dat, lex == 'HLK['), 'i_yod') |>
    select(full, n) |> mutate(class = heb_md('הלך'))
) |>
  mutate(binom.bayes(full, n, type = 'highest', conf.level = 0.95,
                     tol = 1e-9)[, c('mean', 'lower', 'upper')],
         class = factor(class, levels = rev(class)))
verb_classes

p <- verb_classes |>
  ggplot(aes(y = class, x = mean, xmin = lower, xmax = upper)) +
  geom_linerange(linewidth = 0.8, colour = BOOK_BLUE) +
  geom_point(size = 2.5, colour = BOOK_BLUE) +
  geom_text(aes(x = 1.02, label = paste0('n = ', n)), hjust = 0, size = 3,
            colour = BOOK_INK_2) +
  scale_x_continuous(limits = c(0, 1.15), breaks = seq(0, 1, 0.25),
                     labels = scales::percent) +
  labs(x = 'Full spelling (share of forms, 95% interval)', y = NULL) +
  theme_book() +
  markdown_y()
p
save_book_figure(p, 'fig_infa_explore_verb_classes', height = 6)

# Prefix per group of books
prefix_groups <- dat |>
  mutate(prefix = factor(if_else(has_prefix == 1, 'With prefix', 'Without prefix'),
                         levels = c('Without prefix', 'With prefix'))) |>
  group_by(fig_group, prefix) |>
  summarise(full = sum(as.numeric(as.character(has_vowel_letter))), n = n(),
            .groups = 'drop') |>
  mutate(binom.bayes(full, n, type = 'highest', conf.level = 0.95,
                     tol = 1e-9)[, c('mean', 'lower', 'upper')])
prefix_groups

dodge <- position_dodge(width = 0.6)
p <- prefix_groups |>
  mutate(fig_group = fct_rev(fig_group)) |>
  ggplot(aes(y = fig_group, x = mean, xmin = lower, xmax = upper,
             colour = prefix, group = prefix)) +
  geom_linerange(linewidth = 0.8, position = dodge) +
  geom_point(size = 2.2, position = dodge) +
  geom_text(aes(x = 1.02, label = paste0('n = ', n)), hjust = 0, size = 2.6,
            position = dodge, colour = BOOK_INK_2, show.legend = FALSE) +
  scale_colour_manual(values = c(BOOK_BLUE, BOOK_ORANGE),
                      guide = guide_legend(reverse = TRUE)) +
  scale_x_continuous(limits = c(0, 1.15), breaks = seq(0, 1, 0.25),
                     labels = scales::percent) +
  labs(x = 'Full spelling (share of forms, 95% interval)', y = NULL) +
  theme_book()
p
save_book_figure(p, 'fig_infa_explore_prefix', height = 9)

# The ayin-ayin forms (10 forms, 7 lexemes, 7 different passages)
dat |> filter(ay_ay == 1) |>
  select(scroll, book, chapter, verse, lex, g_cons, has_vowel_letter) |>
  arrange(book, chapter, verse)

# ---- 2c. Lexemes ----
# A few lexemes dominate: HLK[ (57 forms) and JD<[ (16 forms).
dat |>
  group_by(lex) |>
  summarise(n = n(), share_full = mean(as.numeric(as.character(has_vowel_letter)))) |>
  arrange(-n) |>
  head(15)

# ---- 2d. Parallel passages: the same form in the MT and in a scroll ----

# Pairs the n-th scroll form with the n-th MT form of the same lexeme in the
# same verse (parallel_forms() in functions.R).
parallel_table <- parallel_forms(dat, occ = raw_occurrences('infa_qal')) |>  # raw-text pairing, 2026-11-05
  select(passage, scroll, corpus, g_cons, mt_g_cons, has_vowel_letter, mt_full, pattern)
parallel_table |> count(corpus, pattern)
write_csv(parallel_table, file.path(IMAGE_FOLDER, 'table_infa_parallel_passages.csv'))

p <- parallel_table |>
  count(corpus, pattern) |>
  mutate(pattern = factor(pattern, levels = c('MT fuller', 'both defective',
                                              'both full', 'scroll fuller'))) |>
  ggplot(aes(y = pattern, x = n)) +
  geom_col(fill = BOOK_BLUE, width = 0.6) +
  geom_text(aes(label = n), hjust = -0.3, size = 3, colour = BOOK_INK_2) +
  facet_wrap(~ corpus) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = 'Number of parallel forms', y = NULL) +
  theme_book() +
  theme(panel.grid.major.y = element_blank(),
        panel.spacing.x = unit(1.2, 'cm'))
p
save_book_figure(p, 'fig_infa_parallel_passages', height = 6)


# ==== 3. DATA MODELLING ====

# Design (item 8 of ../TODO.md section 13, approved 2026-10-17): as in the
# other verb forms.
#   - Priors normal(0, 2.5) on intercept and coefficients, exponential(1) on
#     the SDs (until 2026-10-10: sd 1.5).
#   - corpus_group with MT Pentateuch as reference level; non-QSP is one group.
#   - Grouped 5-fold k-fold (until 2026-10-10: 10 folds).
#   - Model files 'infa2_*' (the old 'infa_*' fits stay on disk, unused).
#   - Suffix (item 9): the infinitive absolute has no suffixes in this
#     dataset (has_suffix is 0 for every form), so there is no suffix term.
#     I-yod stays descriptive (HLK[ and the other I-yod verbs go in opposite
#     directions).

PRIOR_SD <- 2.5
priors <- book_priors(PRIOR_SD)

model_file <- function(id, scale_b = PRIOR_SD) {
  if (scale_b == PRIOR_SD) paste0('infa2_', id, '.rds')
  else paste0('infa2_', id, '_prior', scale_b, '.rds')
}

# ---- 3a. Priors and prior predictive check ----

model_prior_only <- fit_model('infa2_M4_prior_only.rds',
                              has_vowel_letter ~ corpus_group + ay_ay + has_prefix +
                                (1 | scr_book2/lex),
                              dat, priors, sample_prior = 'only')

# Share of full spellings per corpus group under the prior alone: should cover
# the whole range 0-1 without piling up at 0 and 1.
prior_ppc <- group_ppc(model_prior_only, dat, 'corpus_group')
prior_ppc

prior_shares <- posterior_predict(model_prior_only, ndraws = 4000) |> rowMeans()
p <- tibble(share = prior_shares) |>
  ggplot(aes(x = share)) +
  geom_histogram(binwidth = 0.025, boundary = 0, fill = BOOK_GREY, colour = 'white',
                 linewidth = 0.3) +
  geom_vline(xintercept = mean(as.numeric(as.character(dat$has_vowel_letter))),
             colour = BOOK_BLUE, linewidth = 0.8) +
  scale_x_continuous(labels = scales::percent) +
  labs(x = 'Share of full spellings in a simulated dataset (prior only)',
       y = 'Number of simulations',
       caption = 'Blue line: observed share.') +
  theme_book()
p
save_book_figure(p, 'check_infa_prior_predictive', height = 8)
rm(model_prior_only); gc()

# ---- 3b. Candidate models ----

model_specs <- list(
  M0    = has_vowel_letter ~ 1 + (1 | scr_book2/lex),
  M1    = has_vowel_letter ~ corpus + (1 | scr_book2/lex),
  M2    = has_vowel_letter ~ corpus_group + (1 | scr_book2/lex),
  M3    = has_vowel_letter ~ corpus_group + ay_ay + (1 | scr_book2/lex),
  M4    = has_vowel_letter ~ corpus_group + ay_ay + has_prefix + (1 | scr_book2/lex),
  # For comparison: corpus (3 levels) + ayin-ayin, the book's final model
  # infa7 (QSP vs MT and non-QSP together) and infa7 without ayin-ayin.
  M3b   = has_vowel_letter ~ corpus + ay_ay + (1 | scr_book2/lex),
  infa7 = has_vowel_letter ~ is_qsp + ay_ay + (1 | scr_book2/lex),
  Q1    = has_vowel_letter ~ is_qsp + (1 | scr_book2/lex)
)

# Final model M3 = corpus group + ayin-ayin (author, 2026-10-18; infa7 not
# chosen because it merges the MT groups, see REPORT.md). The drop-one
# models, prior refits and robustness fits below follow FINAL_ID.
FINAL_ID <- 'M3'

# Drop-one comparison for the final model (rule 4): the final model without
# each of its effects. A reduced model that is already in the model set (e.g.
# M3 without ayin-ayin = M2) is reused instead of fitted twice.
fixed_terms <- function(formula) {
  setdiff(attr(terms(formula), 'term.labels'), '1 | scr_book2/lex')
}
drop_one_ids <- character()
for (term in fixed_terms(model_specs[[FINAL_ID]])) {
  reduced <- update(model_specs[[FINAL_ID]], as.formula(paste('. ~ . -', term)))
  existing <- names(keep(model_specs, \(f) setequal(fixed_terms(f), fixed_terms(reduced))))
  id <- if (length(existing) > 0) existing[1] else paste0(FINAL_ID, '_no_', term)
  if (length(existing) == 0) model_specs[[id]] <- reduced
  drop_one_ids[term] <- id
}
drop_one_ids

ensure_model <- function(id, scale_b = PRIOR_SD) {
  if (!file.exists(file.path(MODEL_FOLDER, model_file(id, scale_b)))) {
    fit_model(model_file(id, scale_b), model_specs[[id]], dat,
              book_priors(scale_b, has_fixed = id != 'M0'))
    gc()
  }
  invisible(model_file(id, scale_b))
}

walk(names(model_specs), ensure_model)

for (id in names(model_specs)) {
  cat('\n====', id, '====\n')
  m <- load_model(model_file(id))
  print(fixef(m))
  rm(m); gc()
}

# ---- 3c. Grouped k-fold cross-validation ----
# 5 folds; every scroll-book (scr_book2) is left out as a whole, so the
# prediction for a left-out book relies on the fixed effects.

set.seed(2026)
folds <- loo::kfold_split_grouped(K = 5, x = as.character(dat$scr_book2))

if (RUN_KFOLD) {
  kfolds <- map(set_names(names(model_specs)),
                \(id) kfold_lazy(model_file(id), paste0('infa2_', id, '_k5'), folds))
  kfold_comparison <- loo_compare(kfolds)
  print(kfold_comparison)
  kfold_table <- as.data.frame(kfold_comparison) |>
    rownames_to_column('model') |>
    select(model, elpd_diff, se_diff, elpd_kfold, se_elpd_kfold)
  write_csv(kfold_table, file.path(IMAGE_FOLDER, 'table_infa_kfold.csv'))

  # The final model against the model without each of its effects (rule 4;
  # elpd of the reduced model minus the final model, positive = reduced better).
  drop_one <- drop_one_kfold_table(kfolds, FINAL_ID, drop_one_ids)
  print(drop_one)
  write_csv(drop_one, file.path(IMAGE_FOLDER, 'table_infa_kfold_drop_one.csv'))
}

# ---- 3d. Prior sensitivity and robustness (final model) ----

# Prior sensitivity: the final model with sd 1.5 and 4
walk(c(1.5, 4), \(scale_b) ensure_model(FINAL_ID, scale_b))

# Robustness: the final model without 1QIsaa, and with the two halves of
# 1QIsaa as separate groups (the corpus variable of the final model replaced
# by its 1QIsaa split: corpus_group_isa, corpus_isa or qsp_isa).
SPLIT_VARS <- c(corpus_group = 'corpus_group_isa', corpus = 'corpus_isa', is_qsp = 'qsp_isa')
isa_split_formula <- function(formula) {
  var <- intersect(names(SPLIT_VARS), all.vars(formula))[1]
  update(formula, as.formula(paste('. ~ . -', var, '+', SPLIT_VARS[[var]])))
}
robustness_specs <- list(
  no_1qisaa = list(file = paste0('infa2_', FINAL_ID, '_no_1QIsaa.rds'),
                   formula = model_specs[[FINAL_ID]], data = dat_no_1qisaa),
  isa_split = list(file = paste0('infa2_', FINAL_ID, '_1QIsaa_split.rds'),
                   formula = isa_split_formula(model_specs[[FINAL_ID]]), data = dat)
)
walk(robustness_specs, function(r) {
  if (!file.exists(file.path(MODEL_FOLDER, r$file))) {
    fit_model(r$file, r$formula, r$data, priors)
    gc()
  }
})

# ---- 3e. Final model ----
# Results of the old model set (files infa_*, prior sd 1.5, 10 folds, corpus +
# LBH dummy; runs of 2026-10-08/10), kept for reference until the new run is
# reviewed:
#   Final model infa7 (is_qsp + ay_ay; author, 2026-10-10): QSP 1.44 (0.33 to
#   2.80, pd 0.995), ayin-ayin 1.74 (0.15 to 3.54, pd 0.98); non-QSP (M3b)
#   -0.04 (-1.00 to 0.83); LBH (M3) 1.22 (-0.42 to 2.81, pd 0.93); prefix
#   (M4) -0.19 (-0.89 to 0.53). k-fold (elpd difference to M3): infa7 -0.6
#   (1.5), M4 -1.0 (0.7), M2 -2.0 (1.4), M1 -3.6 (2.0), M0 -4.0 (4.3).
#   Neither effect of infa7 brought a clear k-fold gain (rule 4). Ayin-ayin
#   was not credible with prior sd 1. 1QIsaa I spelled like the MT (-0.05,
#   -1.64 to 1.48); 1QIsaa II 1.52 (-0.36 to 3.43); other QSP 2.39 (0.63 to
#   4.40); without 1QIsaa QSP 2.40 (0.61 to 4.48).
#   Author's review (2026-10-08): the ayin-ayin effect is a property of the
#   verb class; the difference between 1QIsaa I and II fits the known
#   difference between the two halves of the scroll.
# Results of the new model set (infa2_*, prior sd 2.5, 5 folds, run of
# 2026-10-18; log-odds, 95% quantile interval, pd):
#   k-fold (elpd difference to M3, SE): infa7 -0.7 (2.5), M4 -1.1 (0.8),
#   M3_no_corpus_group -1.2 (4.7), M3b -1.4 (2.5), M2 -2.2 (1.4), Q1 -2.6
#   (2.8), M1 -3.5 (2.8), M0 -3.7 (4.9). infa7 vs M3b +0.8 (0.6); infa7 vs
#   Q1 +1.9 (1.4). No model is clearly better than another.
#   M3: QSP vs MT Pentateuch 2.17 (0.68 to 4.01), pd 0.998; MT LBH 1.88
#   (-0.18 to 3.91), pd 0.966; MT other books 0.65, Former Prophets 0.63,
#   non-QSP 0.52 (all pd < 0.89); ayin-ayin 2.38 (0.44 to 4.84), pd 0.993.
#   Drop-one: without corpus group -1.2 (4.7), without ayin-ayin (= M2) -2.2
#   (1.4): no clear gain for either (rule 4).
#   Prior sd 1.5 / 4: QSP pd 0.997 / 0.999, ayin-ayin 0.985 / 0.995 (now
#   credible also under the narrower prior), MT LBH 0.946 / 0.976.
#   Robustness: without 1QIsaa QSP 3.95 (1.53 to 7.12), LBH 1.90 (0.11 to
#   3.90, pd 0.981); 1QIsaa I 0.30 (-1.63 to 2.13), 1QIsaa II 2.48 (0.07 to
#   5.14), other QSP 3.93 (1.43 to 7.18).
#   Comparison models: infa7 QSP vs MT + non-QSP 1.66 (0.44 to 3.29), pd
#   0.998, ayin-ayin 2.30 (0.41 to 4.70); M3b non-QSP vs MT -0.04 (-1.13 to
#   0.89); prefix (M4) -0.27 (-1.02 to 0.47), pd 0.77.
#   M3 contains only credible effects under rules 1-2 (corpus group kept for
#   its QSP level). The author confirmed M3 over infa7
#   (2026-10-18).
final_model <- load_model(model_file(FINAL_ID))
summary(final_model)


# ==== 4. DATA VISUALISATION ====

# ---- 4a. Table of fixed effects ----

fixed_table <- make_fixed_effects_table(final_model)
fixed_table
write_csv(rownames_to_column(fixed_table, 'parameter'),
          file.path(IMAGE_FOLDER, 'table_infa_fixed_effects.csv'))

# ---- 4b. Effects (odds ratios) of the final model ----
# corpus_group coefficients are comparisons with the MT Pentateuch. The labels
# cover every candidate model and the 1QIsaa splits, so the code works for any
# FINAL_ID.

OR_SMALL_BREAKS <- c(1/16, 1/4, 1, 4, 16, 64, 256)
OR_SMALL_LABELS <- c('1/16', '1/4', '1', '4', '16', '64', '256')

GROUP_COEFS <- c(MTFormerProphets = 'MT Former Prophets', MTLBH = 'MT LBH',
                 MTotherbooks = 'MT Other', NonMQSP = 'Non-QSP scrolls',
                 QSP = 'QSP scrolls', `1QIsaaI` = '1QIsaa I', `1QIsaaII` = '1QIsaa II')
group_labels <- function(prefix, reference) {
  set_names(paste(GROUP_COEFS, 'vs', reference), paste0(prefix, names(GROUP_COEFS)))
}
effect_labels <- c(group_labels('b_corpus_group', 'MT Pentateuch'),
                   group_labels('b_corpus_group_isa', 'MT Pentateuch'),
                   group_labels('b_corpus', 'MT'),
                   group_labels('b_corpus_isa', 'MT'),
                   b_is_qsp1 = 'QSP scrolls vs MT and non-QSP scrolls',
                   group_labels('b_qsp_isa', 'MT and non-QSP scrolls'),
                   b_ay_ay1 = paste(heb_md('ע״ע'), 'verbs vs other verbs'),
                   b_has_prefix1 = 'With prefix vs without')
label_levels <- unique(effect_labels)

model_effects <- function(model) {
  coefs <- intersect(names(effect_labels), names(as_draws_df(model)))
  coef_draws(model, set_names(coefs, effect_labels[coefs]))
}

final_coefs <- intersect(names(effect_labels), names(as_draws_df(final_model)))
effects <- model_effects(final_model) |>
  mutate(label = factor(label, levels = rev(label_levels))) |>
  summarise_effects(label, parameter)
effects
write_csv(md_to_csv(effects), file.path(IMAGE_FOLDER, 'table_infa_effects.csv'))

p <- plot_or(effects, label, breaks = OR_SMALL_BREAKS, labels = OR_SMALL_LABELS) +
  markdown_y()
p
save_book_figure(p, 'fig_infa_effects', height = 8)

# ---- 4c. Predicted probability of full spelling ----
# Population level (re_formula = NA): a typical scroll-book and lexeme. One
# row per level of the corpus variable of the final model (no prefix, not
# ayin-ayin), plus an ayin-ayin verb in the reference level.

final_vars <- all.vars(model_specs[[FINAL_ID]])
corpus_var <- intersect(c('corpus_group', 'corpus', 'is_qsp'), final_vars)[1]
corpus_levels <- levels(dat[[corpus_var]])
newdata <- tibble(level = corpus_levels,
                  ay_ay = factor('0', levels = levels(dat$ay_ay)),
                  has_prefix = factor('0', levels = levels(dat$has_prefix)))
if ('ay_ay' %in% final_vars) {
  newdata <- bind_rows(newdata,
                       mutate(newdata[1, ], ay_ay = factor('1', levels = levels(dat$ay_ay))))
}
newdata[[corpus_var]] <- factor(newdata$level, levels = corpus_levels)
# Labels as in the book: 'MT Other' for the level 'MT other books'.
level_names <- if (corpus_var == 'is_qsp') {
  c('0' = 'MT and non-QSP scrolls', '1' = 'QSP scrolls')
} else {
  set_names(str_replace(corpus_levels, '^MT other books$', 'MT Other'), corpus_levels)
}
newdata <- newdata |>
  mutate(condition = paste0(level_names[level],
                            if_else(ay_ay == '1', paste0(', ', heb_md('ע״ע'), ' verb'), '')))

predicted <- newdata |>
  add_epred_draws(final_model, re_formula = NA) |>
  group_by(condition) |>
  median_qi(.epred, .width = c(0.66, 0.95)) |>
  mutate(condition = factor(condition, levels = rev(newdata$condition)))
predicted
write_csv(md_to_csv(predicted), file.path(IMAGE_FOLDER, 'table_infa_predicted.csv'))

p <- predicted |>
  ggplot(aes(y = condition, x = .epred, xmin = .lower, xmax = .upper)) +
  geom_pointinterval(colour = BOOK_BLUE, point_size = 2.5,
                     interval_size_range = c(0.8, 2)) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25),
                     labels = scales::percent) +
  labs(x = 'Predicted probability of full spelling', y = NULL,
       caption = paste(OR_CAPTION, 'Typical book and lexeme, no prefix.', sep = '\n')) +
  theme_book() +
  markdown_y()
p
save_book_figure(p, 'fig_infa_predicted', height = 8)

# ---- 4d. Robustness and prior sensitivity ----
# The effects of the final model in the robustness fits and with prior sd 1.5
# and 4. In the 1QIsaa split, "QSP scrolls" are the QSP scrolls other than
# 1QIsaa, and 1QIsaa I and II are extra panels.

robustness_models <- list(
  'Final model'          = model_file(FINAL_ID),
  'Without 1QIsaa'       = robustness_specs$no_1qisaa$file,
  '1QIsaa I/II separate' = robustness_specs$isa_split$file,
  'Prior sd 1.5'         = model_file(FINAL_ID, 1.5),
  'Prior sd 4'           = model_file(FINAL_ID, 4)
)
robustness <- imap_dfr(robustness_models, function(file, variant) {
  m <- load_model(file)
  out <- model_effects(m) |> mutate(variant = variant)
  rm(m); gc()
  out
}) |>
  mutate(label = factor(label, levels = label_levels),
         variant = factor(variant, levels = rev(names(robustness_models)))) |>
  summarise_effects(label, variant)
robustness
write_csv(md_to_csv(robustness), file.path(IMAGE_FOLDER, 'table_infa_robustness.csv'))

p <- plot_or(robustness, variant, breaks = OR_SMALL_BREAKS, labels = OR_SMALL_LABELS) +
  facet_wrap(~ label, ncol = 2) +
  labs(caption = paste('The final model and its robustness fits.', OR_CAPTION, sep = '\n')) +
  theme(strip.text.x.top = ggtext::element_markdown(colour = BOOK_INK, face = 'bold', hjust = 0))
p
save_book_figure(p, 'fig_infa_robustness', height = 20)

# ---- 4e. Effects not in the final model (no credible effect) ----
# Estimates from the comparison models, for the effects the final model does
# not contain.

not_in_final_specs <- tribble(
  ~label,                                          ~id,     ~parameter,
  'With prefix vs without (M4)',                   'M4',    'b_has_prefix1',
  'Non-QSP scrolls vs MT (M3b)',                   'M3b',   'b_corpusNonMQSP',
  'QSP scrolls vs MT (M3b)',                       'M3b',   'b_corpusQSP',
  'QSP scrolls vs MT and non-QSP scrolls (infa7)', 'infa7', 'b_is_qsp1'
) |>
  filter(id != FINAL_ID, !parameter %in% final_coefs) |>
  mutate(file = map_chr(id, model_file)) |>
  select(label, file, parameter)
other_effects <- effects_not_in_final_model(not_in_final_specs)
other_effects
write_csv(other_effects, file.path(IMAGE_FOLDER, 'table_infa_effects_not_in_final_model.csv'))

p <- plot_effects_not_in_final_model(
  other_effects, OR_SMALL_BREAKS, OR_SMALL_LABELS,
  caption = paste('Estimates from the comparison models.', OR_CAPTION, sep = '\n'))
p
save_book_figure(p, 'fig_infa_effects_not_in_final_model', height = 6)

# ---- 4f. Random intercepts (checks, not for the book) ----

p <- plot_random_intercepts(final_model, 'scr_book2', text_size = 6) + theme_book()
save_book_figure(p, 'check_infa_random_books', height = 18)


# ==== 5. MODEL VERIFICATION ====

# Convergence (Rhat, ESS, divergences), trace and density plots, posterior
# predictive checks, LOO (shown for completeness; unreliable here), Bayes R2.
# The classification numbers it prints are in-sample and optimistic.
verification <- verify_model(final_model, IMAGE_FOLDER, 'check_infa')

# Observed vs predicted share of full spellings per group of books.
ppc_groups <- group_ppc(final_model, dat, 'law_phase3')
ppc_groups

p <- ppc_groups |>
  mutate(group = fct_rev(group)) |>
  ggplot(aes(y = group)) +
  geom_linerange(aes(xmin = l95, xmax = u95), colour = BOOK_GREY, linewidth = 0.8) +
  geom_linerange(aes(xmin = l50, xmax = u50), colour = BOOK_GREY, linewidth = 2.2) +
  geom_point(aes(x = observed), colour = BOOK_BLUE, size = 2.5) +
  scale_x_continuous(limits = c(0, 1), labels = scales::percent) +
  labs(x = 'Share of full spellings',
       y = NULL,
       caption = 'Blue: observed. Grey: predicted by the model (50% and 95% interval).') +
  theme_book()
p
save_book_figure(p, 'check_infa_ppc_groups', height = 8)
