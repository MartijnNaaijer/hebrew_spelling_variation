################################################################################
# infc_qal_lamed_he/analysis.R
#
# Dataset:  infc_qal_lamed_he.csv - qal infinitive construct of III-he verbs in
#           the MT and the Dead Sea Scrolls (no SP forms).
# Outcome:  has_vowel_letter (1 = full ending -WT, e.g. <FWT; 0 = defective -T,
#           <FT).
# Questions:
#   1. Do the QSP and non-QSP scrolls spell the ending more fully than the MT?
#   2. Within the MT: do the groups of books differ (Pentateuch, Former
#      Prophets, LBH, other books)?
#   3. Is the ending less often full before a pronominal suffix (-TW vs -WTW)?
#
# Status (2026-10-09): rebuilt on the design of infc_qal_triliteral; all models
# fitted 2026-10-09 (see REPORT.md). Final model: M4p = M3 + prefix in the MT
# Pentateuch (author, 2026-10-12; M3 before).
#
# Started from ../../infc_qal_lamed_he_cleaned.R. Changes w.r.t. that script:
#   - Predictors: corpus_group (MT split by group of books, scrolls one group
#     per corpus) instead of law_phase3; the scrolls are almost always full
#     (QSP 59/59, non-QSP Former Prophets 10/10 and Other 31/31, non-QSP LBH
#     only 2 forms), so splitting them by group of books cannot be estimated.
#   - Prefix: descriptive only, plus an additive check model M4 (author,
#     2026-10-09). In the MT 88.7% (no prefix) vs 88.4% (prefix) is full; the
#     old final model m11 (law_phase3 * has_prefix) rested on cells of 1-6
#     forms. m11 is kept as a comparison model.
#   - Suffix: plain has_prs, additive (author, 2026-10-09).
#   - Explicit priors (book_priors, normal(0, 2.5), exponential(1) on SDs) with
#     sensitivity sd 1.5 and 4; grouped k-fold instead of LOO (177 of 309
#     book x lexeme groups contain one form). Bayes factors dropped (author,
#     2026-10-14/17).
#   - Isaiah manuscripts model dropped for now (all 42 Isaiah forms in the
#     scrolls are full); to be looked at later (see ../TODO.md).
#   - Book figures (fig_infc_lh_*) replace the explore_* plots and the
#     unsaved base-graphics mosaic plots per Pentateuch book; the MT books
#     figure is now saved.
#
# CHANGES 2026-10-17 (harmonisation of the verb forms, ../TODO.md section 13):
#   - Bayes factors dropped (author, 2026-10-14/17): RUN_BAYES_FACTORS and
#     the Bayes factor code of section 3d removed;
#     table_infc_lh_bayes_factors.csv is no longer written.
#   - Effect summaries with the shared helpers of ../functions.R
#     (summarise_effects, plot_or, effects_not_in_final_model): median, 66%
#     and 95% quantile intervals and pd, instead of median_hdi. The tables
#     now have one row per effect (columns .lower/lower66/upper66/.upper, pd).
#   - Corpus groups reported against the MT Pentateuch (contrasts computed
#     from the draws; the model reference stays MT other books until the
#     refit, ../TODO.md section 13 item 6).
#   - Robustness figure faceted by effect; it now includes the prior
#     sensitivity of M3 (the stored sd 1.5 and 4 fits of the former Bayes
#     factor section). M4p itself has no prior refits yet (item 7).
#
# CHANGES 2026-10-17 (refit, ../TODO.md section 13 items 6-10; approved by the
# author 2026-10-17):
#   - MT Pentateuch is the reference level of corpus_group (item 6). All model
#     files and k-fold stems have the new prefix 'infc_lh2_'; the old infc_lh_*
#     fits (reference MT other books) stay on disk, unused.
#   - Prior sensitivity of the final model M4p with sd 1.5 and 4 (item 7);
#     it replaces the M3 prior variants in the robustness figure.
#   - has_prs stays the suffix variable (item 9): has_nme = 1 for every form
#     here, so the shared has_suffix would be 1 everywhere.
#   - Sampler: warmup 1000, iter 3000 (the fit_model() default, item 10).
#   - Numbers quoted in comments: the refit results are in section 3f (run of
#     2026-10-18); the history there keeps the old numbers (reference MT
#     other books, sampler 2000/6000), marked as such.
#
# CHANGES 2026-10-19 (book figures for §9.5, BOOK_CHANGES_9.5.md):
#   - Charis and Hebrew in SBL Hebrew; 'MT Other' instead of 'MT other books'
#     (labels only); legends 'with/without pronominal suffix'; no model IDs
#     in the labels and notes of fig_infc_lh_effects_not_in_final_model.
#   - New figures fig_infc_lh_groups_all (Fig. 9.30) and
#     fig_infc_lh_pent_books_prefix (Fig. 9.33).
################################################################################


# ==== 0. SETUP ====

library(tidyverse)
library(brms)
library(bayesplot)
library(tidybayes)
library(bayestestR)
library(binom)
library(loo)

ANALYSIS_DIR <- 'C:/Users/geitb/Dropbox/monograph_orthography/verbs/analysis_verbs'
VERB_FORM <- 'infc_qal_lamed_he'
IMAGE_FOLDER <- file.path(ANALYSIS_DIR, VERB_FORM, 'figures')

source(file.path(ANALYSIS_DIR, 'config.R'))
source(file.path(ANALYSIS_DIR, 'functions.R'))

DATASET <- 'infc_qal_lamed_he.csv'

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

dat$book_group <- factor(case_when(dat$book %in% LAW_BOOKS ~ 'Pentateuch',
                                   dat$book %in% EBH_BOOKS ~ 'Former Prophets',
                                   dat$book %in% LBH_BOOKS ~ 'LBH',
                                   TRUE ~ 'Other'),
                         levels = c('Pentateuch', 'Former Prophets', 'LBH', 'Other'))

# Corpus group (6 levels), as in infc_qal_triliteral: the MT split by group of
# books, the scrolls as one group per corpus (they are almost always full).
# Reference level: MT Pentateuch (as in every verb form; author, 2026-10-15;
# until 2026-10-17 MT other books).
dat$corpus_group <- factor(case_when(dat$corpus == 'MT' & dat$book_group == 'Other' ~ 'MT other books',
                                     dat$corpus == 'MT' ~ paste('MT', dat$book_group),
                                     TRUE ~ as.character(dat$corpus)),
                           levels = c('MT Pentateuch', 'MT Former Prophets', 'MT LBH',
                                      'MT other books', 'Non-QSP', 'QSP'))
stopifnot(levels(dat$corpus_group)[1] == 'MT Pentateuch')

# Suffix: the models use has_prs (pronominal suffix). In this dataset has_nme
# = 1 for every form (the -WT ending is coded as a nominal ending), so the
# shared has_suffix (has_prs | has_nme | has_hloc) would be 1 everywhere;
# has_prs is the suffix variable here (../TODO.md section 13 item 9).
stopifnot(all(dat$has_suffix == 1))

# Suffix type, for the exploration only (the models use has_prs): the 3ms
# suffix (-TW / -WTW) is defective far more often than the other suffixes.
dat$suffix_type <- factor(case_when(dat$has_prs == 0 ~ 'No suffix',
                                    dat$prs == 'W' ~ 'Suffix 3ms (-W)',
                                    TRUE ~ 'Other suffix'),
                          levels = c('No suffix', 'Other suffix', 'Suffix 3ms (-W)'))

# Prefix in the MT Pentateuch (author, 2026-10-12): the prefix lowers fullness
# only there (no suffix: 14/14 full without vs 127/165 with a prefix); in the
# other groups nearly all forms are full with or without a prefix. Used in the
# final model M4p instead of a general prefix term or a full interaction.
dat$pent_prefix <- factor(as.numeric(dat$corpus_group == 'MT Pentateuch' &
                                       dat$has_prefix == 1), levels = c('0', '1'))

# Passage (book, chapter, verse, lexeme), to find parallel forms.
dat$passage <- paste(dat$book, dat$chapter, dat$verse, dat$lex)

dim(dat)                                     # 963 forms, 99 defective
table(dat$corpus_group, dat$has_vowel_letter)
table(dat$has_prs, dat$has_vowel_letter, dat$corpus)
table(dat$has_prefix, dat$has_vowel_letter, dat$corpus)
table(dat$prefix, dat$corpus)


# ==== 2. EXPLORATORY ANALYSIS ====

suffix_label <- function(has_prs) factor(if_else(has_prs == 1, 'With pronominal suffix', 'Without pronominal suffix'),
                                         levels = c('Without pronominal suffix', 'With pronominal suffix'))

# ---- 2a. Groups of books, with and without pronominal suffix ----
# MT Pentateuch 71% full, the other MT groups 92-96%; the scrolls 92-100%.

groups_prs <- shares_by(dat, law_phase3, has_prs) |>
  filter(law_phase3 != 'Non-QSP LBH') |>          # 2 forms
  mutate(row = fct_rev(droplevels(law_phase3)), suffix = suffix_label(has_prs))
groups_prs
write_csv(select(groups_prs, -row), file.path(IMAGE_FOLDER, 'table_infc_lh_groups.csv'))

p <- plot_shares(groups_prs, colour_var = 'suffix', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE)) +
  labs(caption = 'Non-QSP LBH (2 forms) not shown.')
p
save_book_figure(p, 'fig_infc_lh_groups', height = 12)

# All forms per document group (for the book, Fig. 9.30)
groups_all <- shares_by(dat, law_phase3) |>
  mutate(row = fct_rev(law_phase3))
p <- plot_shares(groups_all)
p
save_book_figure(p, 'fig_infc_lh_groups_all', height = 8)

# ---- 2b. Suffix types per corpus ----
# MT: no suffix 94% full, 3ms suffix 30% (10 of 33), other suffixes 69%.

suffix_types <- shares_by(dat, corpus, suffix_type) |>
  mutate(row = fct_rev(corpus))
suffix_types
write_csv(select(suffix_types, -row), file.path(IMAGE_FOLDER, 'table_infc_lh_suffix_types.csv'))

p <- plot_shares(suffix_types, colour_var = 'suffix_type', dodge_width = 0.7)
p
save_book_figure(p, 'fig_infc_lh_suffix_types', height = 8)

# ---- 2c. Parallel passages: the same form in the MT and in a scroll ----
# Scroll fuller 17 times (non-QSP 10, QSP 7), MT fuller never; both full 113,
# both defective 4 (all non-QSP).

# parallel_forms() (functions.R) pairs the n-th form of a lexeme in a verse in
# the scroll with the n-th form in the MT. (The first version paired every
# scroll form with the first MT form of the lexeme in the verse; fixed
# 2026-10-09.)
parallel_table <- parallel_forms(dat, occ = raw_occurrences('infc_qal')) |>  # raw-text pairing, 2026-11-05
  select(passage, scroll, corpus, lex, g_cons, mt_g_cons, has_prs, has_vowel_letter,
         mt_full, pattern)
parallel_table |> count(corpus, pattern)
write_csv(parallel_table, file.path(IMAGE_FOLDER, 'table_infc_lh_parallel_passages.csv'))

p <- parallel_table |>
  mutate(corpus = droplevels(corpus)) |>
  count(corpus, pattern) |>
  mutate(pattern = factor(pattern, levels = c('MT fuller', 'both defective',
                                              'both full', 'scroll fuller'))) |>
  complete(corpus, pattern, fill = list(n = 0)) |>
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
save_book_figure(p, 'fig_infc_lh_parallel_passages', height = 6)

# ---- 2d. Prefix (descriptive; additive check model M4 in section 3) ----

prefix_label <- function(has_prefix) factor(if_else(has_prefix == 1, 'With prefix', 'Without prefix'),
                                            levels = c('Without prefix', 'With prefix'))

prefix_groups <- shares_by(dat, corpus_group, has_prefix) |>
  mutate(row = fct_rev(fct_recode(corpus_group, 'MT Other' = 'MT other books')),
         prefix = prefix_label(has_prefix))
prefix_groups

p <- plot_shares(prefix_groups, colour_var = 'prefix', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE))
p
save_book_figure(p, 'fig_infc_lh_explore_prefix', height = 9)

prefixes <- dat |>
  mutate(prefix_type = factor(case_when(prefix == '' ~ 'No prefix',
                                        prefix %in% c('L', 'WL') ~ 'L / WL',
                                        prefix %in% c('B', 'WB') ~ 'B / WB',
                                        prefix %in% c('K', 'WK') ~ 'K / WK',
                                        prefix == 'M' ~ 'M',
                                        TRUE ~ 'Other prefix'),
                              levels = c('L / WL', 'B / WB', 'K / WK', 'M',
                                         'Other prefix', 'No prefix'))) |>
  shares_by(corpus, prefix_type)
prefixes
write_csv(prefixes, file.path(IMAGE_FOLDER, 'table_infc_lh_prefixes.csv'))

# ---- 2e. MT books (forms without suffix) ----
# The defective forms cluster in the Pentateuch, above all Exodus (21 of 46
# defective, in chapters 1-24 and 25-40 alike).

mt_books <- shares_by(filter(dat, corpus == 'MT' & has_prs == 0), book2) |>
  arrange(mean) |>
  mutate(row = gsub('_', ' ', book2),
         row = factor(row, levels = row))
mt_books

p <- plot_shares(mt_books) +
  labs(caption = 'MT, forms without pronominal suffix.')
p
save_book_figure(p, 'fig_infc_lh_explore_mt_books', height = 18)

# The books of the MT Pentateuch with and without a prefix, forms without a
# pronominal suffix (for the book, Fig. 9.33): the defective forms are all
# prefixed (14 of 14 forms without a prefix are full).
pent_books <- dat |>
  filter(corpus_group == 'MT Pentateuch', has_prs == 0) |>
  mutate(book = factor(book, levels = c('Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy'))) |>
  shares_by(book, has_prefix) |>
  mutate(row = fct_rev(book), prefix = prefix_label(has_prefix))
pent_books
p <- plot_shares(pent_books, colour_var = 'prefix', dodge_width = 0.6,
                 colours = c(BOOK_BLUE, BOOK_ORANGE)) +
  labs(caption = 'MT Pentateuch, forms without pronominal suffix.')
p
save_book_figure(p, 'fig_infc_lh_pent_books_prefix', height = 9)

# ---- 2f. Lexemes ----
# No lexeme needs its own fixed effect: <FH[ (37% of the data) is 91% full,
# all forms 90%.

lexemes <- dat |>
  group_by(lex) |>
  summarise(n = n(), n_mt = sum(corpus == 'MT'),
            share_full = mean(as.numeric(as.character(has_vowel_letter)))) |>
  arrange(-n)
head(lexemes, 15)
write_csv(lexemes, file.path(IMAGE_FOLDER, 'table_infc_lh_lexemes.csv'))


# ==== 3. DATA MODELLING ====
#
# Decisions (author, 2026-10-08/09; ../TODO.md section 8):
#   - Random part nested: (1 | scr_book2/lex).
#   - Same design as infc_qal_triliteral: corpus_group, priors normal(0, 2.5)
#     with exponential(1) on the SDs, sensitivity sd 1.5 and 4.
#   - Pronominal suffix: plain has_prs, additive (an interaction with the
#     corpus cannot be estimated: suffixed forms in the scrolls are 27/30 full).
#   - Prefix: descriptive, plus the additive check model M4.
#   - Models: M0 null; M1 corpus; M2 corpus_group; M3 M2 + has_prs (expected
#     final); M4 M3 + has_prefix; n1 law_phase3 + has_prs and m11 (old final
#     model, has_prs + law_phase3 * has_prefix) for comparison.

PRIOR_SD <- 2.5
priors <- book_priors(PRIOR_SD)
# Model files and k-fold stems (new prefix with the reference level MT
# Pentateuch, 2026-10-17; the old infc_lh_* fits are not used).
PREFIX <- 'infc_lh2_'

# ---- 3a. Prior predictive check ----

model_prior_only <- fit_model(paste0(PREFIX, 'M3_prior_only.rds'),
                              has_vowel_letter ~ corpus_group + has_prs +
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
save_book_figure(p, 'check_infc_lh_prior_predictive', height = 8)
rm(model_prior_only); gc()

# ---- 3b. Candidate models ----

model_specs <- list(
  M0  = has_vowel_letter ~ 1 + (1 | scr_book2/lex),
  M1  = has_vowel_letter ~ corpus + (1 | scr_book2/lex),
  M2  = has_vowel_letter ~ corpus_group + (1 | scr_book2/lex),
  M3  = has_vowel_letter ~ corpus_group + has_prs + (1 | scr_book2/lex),
  M4  = has_vowel_letter ~ corpus_group + has_prs + has_prefix + (1 | scr_book2/lex),
  n1  = has_vowel_letter ~ law_phase3 + has_prs + (1 | scr_book2/lex),
  m11 = has_vowel_letter ~ has_prs + law_phase3 * has_prefix + (1 | scr_book2/lex),
  # Drop-one comparison for M3 (rule 4, 2026-10-11); M3 without the suffix is M2.
  M3_no_corpus_group = has_vowel_letter ~ has_prs + (1 | scr_book2/lex),
  # Final model (author, 2026-10-12): prefix effect only in the MT Pentateuch.
  M4p = has_vowel_letter ~ corpus_group + has_prs + pent_prefix + (1 | scr_book2/lex)
)
# Drop-one comparison for the final model M4p (rule 4); M4p without
# pent_prefix is M3.
model_specs <- c(model_specs,
                 drop_one_formulas(model_specs$M4p, c('corpus_group', 'has_prs'), 'M4p'))
model_file <- function(id, scale_b = PRIOR_SD) {
  if (scale_b == PRIOR_SD) paste0(PREFIX, id, '.rds')
  else paste0(PREFIX, id, '_prior', scale_b, '.rds')
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

for (id in names(model_specs)) {
  cat('\n====', id, '====\n')
  m <- load_model(model_file(id))
  print(fixef(m))
  rm(m); gc()
}

# ---- 3c. Grouped k-fold cross-validation ----
# 5 folds; every scroll-book is left out as a whole.

set.seed(2026)
folds <- loo::kfold_split_grouped(K = 5, x = as.character(dat$scr_book2))

if (RUN_KFOLD) {
  kfolds <- map(set_names(names(model_specs)),
                \(id) kfold_lazy(model_file(id), paste0(PREFIX, id, '_k5'), folds))
  kfold_comparison <- loo_compare(kfolds)
  print(kfold_comparison)
  kfold_table <- as.data.frame(kfold_comparison) |>
    rownames_to_column('model') |>
    select(model, elpd_diff, se_diff, elpd_kfold, se_elpd_kfold)
  write_csv(kfold_table, file.path(IMAGE_FOLDER, 'table_infc_lh_kfold.csv'))

  # Final model M4p against the model without each of its effects (rule 4).
  drop_one <- drop_one_kfold_table(kfolds, 'M4p',
                                   c('corpus group' = 'M4p_no_corpus_group',
                                     'pronominal suffix' = 'M4p_no_has_prs',
                                     'prefix in the MT Pentateuch' = 'M3'))
  print(drop_one)
  write_csv(drop_one, file.path(IMAGE_FOLDER, 'table_infc_lh_kfold_drop_one.csv'))
}

# ---- 3d. Prior sensitivity of the final model ----
# M4p refitted with prior sd 1.5 and 4 (../TODO.md section 13 item 7). No
# Bayes factors (author, 2026-10-14/17).

walk(c(1.5, 4), \(scale_b) ensure_model('M4p', scale_b))

# ---- 3e. Robustness ----
# Fitted and stored here; their coefficients are read in section 4d.

robustness_specs <- list(
  no_1qisaa = list(file = paste0(PREFIX, 'M3_no_1QIsaa.rds'), formula = model_specs$M3,
                   data = filter(dat, !scroll %in% c('1QisaaI', '1QisaaII')) |> droplevels()),
  no_fh     = list(file = paste0(PREFIX, 'M3_no_FH.rds'), formula = model_specs$M3,
                   data = filter(dat, lex != '<FH[') |> droplevels()),
  # Credible-effects rule 3(i) (2026-10-11): does the prefix effect of M4
  # survive without the two lexemes that carry it descriptively?
  m4_no_hjh_fh = list(file = paste0(PREFIX, 'M4_no_HJH_FH.rds'), formula = model_specs$M4,
                      data = filter(dat, !lex %in% c('HJH[', '<FH[')) |> droplevels())
)
walk(robustness_specs, function(r) {
  if (!file.exists(file.path(MODEL_FOLDER, r$file))) {
    fit_model(r$file, r$formula, r$data, priors)
    gc()
  }
})

# ---- 3f. Final model ----
# Results of the refit (infc_lh2_*, reference MT Pentateuch, run of
# 2026-10-18): k-fold (elpd difference to the best model, SE):
# M4p_no_corpus_group 0; M4p -4.1 (5.0); m11 -7.7 (5.8); M3 -8.9 (6.5);
# M4 -13.2 (6.5); n1 -13.2 (7.5); M3_no_corpus_group -52.6 (10.8);
# M2 -58.1 (11.6); M4p_no_has_prs -61.3 (11.8); M1 -91.4; M0 -93.1.
# Drop-one for M4p (reduced minus M4p): corpus group +4.1 (5.0), suffix
# -57.2 (11.4), prefix in the MT Pentateuch (= M3) -4.8 (4.5). M4 vs M3
# -4.3 (2.4); M4p vs M4 +9.2 (4.6).
# M4p effects (log-odds, 95%, pd): prefix in MT Pentateuch -2.88 (-4.47 to
# -1.45), 1.00; suffix -3.88 (-4.76 to -3.14), 1.00; QSP vs MT Pentateuch
# (forms without a prefix) 3.38 (0.73 to 6.64), 0.995; the other groups are
# not credible (MT LBH -1.24, pd 0.89). Prior sd 1.5 / 4: all credible
# effects stay credible (QSP pd 0.987 / 0.997).
# General prefix (M4): -1.17 (-2.16 to -0.24), pd 0.994; without HJH[ and
# <FH[ -0.32 (-1.49 to 0.74), pd 0.71.
# (The history below quotes the old fits, reference MT other books.)
# M4p (author, 2026-10-12): M3 + a prefix effect in the MT Pentateuch only.
# History: M3 was chosen first (2026-10-09; M4's general prefix term predicts
# worse in k-fold, -2.8, SE 2.6) and confirmed under the credible-effects
# rules (2026-10-11; the general prefix rests on HJH[ and <FH[). The author
# then decided to keep the prefix, even if not very robust. The descriptive
# check shows the prefix effect only in the MT Pentateuch (no suffix: 14/14
# full without vs 127/165 with a prefix; elsewhere nearly all forms are full),
# so it is modelled as one dummy (pent_prefix) rather than as a general term
# (M4) or a corpus x prefix interaction (cells of 4-14 forms without a
# prefix, mostly all full; cf. the old m11, not supported). See REPORT.md.
final_model <- load_model(model_file('M4p'))
summary(final_model)


# ==== 4. DATA VISUALISATION ====

# ---- 4a. Table of fixed effects ----

fixed_table <- make_fixed_effects_table(final_model)
fixed_table
write_csv(rownames_to_column(fixed_table, 'parameter'),
          file.path(IMAGE_FOLDER, 'table_infc_lh_fixed_effects.csv'))

# ---- 4b. Effects (odds ratios) ----
# The groups are shown against the MT Pentateuch (the reference level since
# 2026-10-17). effect_draws() takes the difference of the coefficients per
# draw, with a missing coefficient (the reference level) counted as 0, so it
# also works for a model with another reference level. In M4p the MT
# Pentateuch level is that of the Pentateuch forms without a prefix, so the
# group contrasts are against those forms.

PENT <- 'b_corpus_groupMTPentateuch'
GROUP_COEF <- c('MT Former Prophets' = 'b_corpus_groupMTFormerProphets',
                'MT LBH'             = 'b_corpus_groupMTLBH',
                'MT Other'           = 'b_corpus_groupMTotherbooks',
                'Non-QSP scrolls'    = 'b_corpus_groupNonMQSP',
                'QSP scrolls'        = 'b_corpus_groupQSP')
OTHER_COEF <- c(b_has_prs1     = 'Pronominal suffix (vs none)',
                b_has_prefix1  = 'Prefix (vs none)',
                b_pent_prefix1 = 'Prefix in MT Pentateuch (vs none)')

# Draws (logit scale) of the group contrasts vs the MT Pentateuch and of the
# other coefficients of a model with corpus_group.
effect_draws <- function(model) {
  d <- as_draws_df(model)
  coef_or_0 <- function(name) if (name %in% names(d)) d[[name]] else 0
  bind_rows(
    imap_dfr(GROUP_COEF, \(coef, group)
      tibble(label = paste(group, 'vs MT Pentateuch'),
             value = coef_or_0(coef) - coef_or_0(PENT))),
    imap_dfr(OTHER_COEF[names(OTHER_COEF) %in% names(d)], \(label, coef)
      tibble(label = label, value = d[[coef]]))
  )
}
effect_order <- c(paste(names(GROUP_COEF), 'vs MT Pentateuch'), OTHER_COEF)

effects <- effect_draws(final_model) |>
  summarise_effects(label) |>
  mutate(label = factor(label, levels = rev(effect_order))) |>
  arrange(desc(label))
effects
write_csv(effects, file.path(IMAGE_FOLDER, 'table_infc_lh_effects.csv'))

p <- plot_or(effects, label,
             caption = paste0('Groups vs the MT Pentateuch forms without a prefix; suffix and prefix vs none.\n',
                              OR_CAPTION)) +
  theme(plot.caption.position = 'plot')
p
save_book_figure(p, 'fig_infc_lh_effects', height = 7)

# ---- 4b2. Effects not in the final model ----
# The general prefix term of M4 (all groups; replaced in the final model by
# the prefix in the MT Pentateuch). It is credible (refit: pd 0.994) but
# rests on HJH[ and <FH[: without them it shrinks to about a quarter (-1.17
# -> -0.32, pd 0.71; refit 2026-10-18; old fits 2026-10-11: a third).

not_in_final <- effects_not_in_final_model(tribble(
  ~label,                                       ~file,                     ~parameter,
  'General prefix effect (vs none)',            model_file('M4'),          'b_has_prefix1',
  paste('General prefix effect, without', heb_md('היה'), 'and', heb_md('עשה')),
                                                paste0(PREFIX, 'M4_no_HJH_FH.rds'), 'b_has_prefix1'
))
not_in_final
write_csv(md_to_csv(not_in_final), file.path(IMAGE_FOLDER, 'table_infc_lh_effects_not_in_final_model.csv'))
p <- plot_effects_not_in_final_model(
  not_in_final,
  caption = paste0('Not in the final model, which has a prefix effect for the MT Pentateuch only.\n',
                   OR_CAPTION)) +
  theme(plot.caption.position = 'plot') +
  markdown_y()
p
save_book_figure(p, 'fig_infc_lh_effects_not_in_final_model', height = 4)

# ---- 4c. Predicted probability of full spelling ----
# Population level (re_formula = NA): a typical scroll-book and lexeme.

newdata <- expand_grid(corpus_group = factor(levels(dat$corpus_group),
                                             levels = levels(dat$corpus_group)),
                       has_prs = factor(c('0', '1'), levels = levels(dat$has_prs)),
                       pent_prefix = factor(c('0', '1'), levels = c('0', '1'))) |>
  # The prefix dummy applies only to the MT Pentateuch
  filter(pent_prefix == '0' | corpus_group == 'MT Pentateuch') |>
  mutate(condition = case_when(corpus_group == 'MT Pentateuch' & pent_prefix == '1' ~
                                 'MT Pentateuch, with prefix',
                               corpus_group == 'MT Pentateuch' ~ 'MT Pentateuch, no prefix',
                               corpus_group == 'Non-QSP' ~ 'Non-QSP scrolls',
                               corpus_group == 'QSP' ~ 'QSP scrolls',
                               corpus_group == 'MT other books' ~ 'MT Other',
                               TRUE ~ as.character(corpus_group)),
         suffix = suffix_label(has_prs))

condition_order <- c('MT Pentateuch, no prefix', 'MT Pentateuch, with prefix',
                     'MT Former Prophets', 'MT LBH', 'MT Other',
                     'Non-QSP scrolls', 'QSP scrolls')
predicted <- newdata |>
  add_epred_draws(final_model, re_formula = NA) |>
  group_by(condition, suffix) |>
  # Equal-tailed intervals: HDIs of probabilities piled up near 100% (QSP)
  # split into several pieces.
  median_qi(.epred, .width = c(0.66, 0.95)) |>
  mutate(condition = factor(condition, levels = rev(condition_order)))
predicted
write_csv(predicted, file.path(IMAGE_FOLDER, 'table_infc_lh_predicted.csv'))

p <- predicted |>
  ggplot(aes(y = condition, x = .epred, xmin = .lower, xmax = .upper, colour = suffix)) +
  geom_pointinterval(point_size = 2.5, interval_size_range = c(0.8, 2),
                     position = position_dodge(width = 0.6)) +
  scale_colour_manual(values = c(BOOK_BLUE, BOOK_ORANGE),
                      guide = guide_legend(reverse = TRUE)) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25),
                     labels = scales::percent) +
  labs(x = 'Predicted probability of full spelling', y = NULL,
       caption = paste(OR_CAPTION, 'Typical book and lexeme.', sep = '\n')) +
  theme_book()
p
save_book_figure(p, 'fig_infc_lh_predicted', height = 10)

# ---- 4d. Robustness and prior sensitivity ----
# The robustness fits are variants of M3 (and M4); they are compared with M3
# itself. In M3 the MT Pentateuch contrast is that of all Pentateuch forms;
# in M4 and M4p that of the forms without a prefix. Prior sensitivity: the
# final model M4p with sd 1.5 and 4 (since 2026-10-17).

robustness_variants <- c(
  'M3 (all data)'            = model_file('M3'),
  'M3 without 1QIsaa'        = paste0(PREFIX, 'M3_no_1QIsaa.rds'),
  'M3 without <FH['          = paste0(PREFIX, 'M3_no_FH.rds'),
  'M4 (prefix everywhere)'   = model_file('M4'),
  'M4 without HJH[ and <FH[' = paste0(PREFIX, 'M4_no_HJH_FH.rds'),
  'M4p (final model)'        = model_file('M4p'),
  'M4p, prior sd 1.5'        = model_file('M4p', 1.5),
  'M4p, prior sd 4'          = model_file('M4p', 4)
)
robust_effects <- c('MT Other vs MT Pentateuch', 'MT LBH vs MT Pentateuch',
                    'Non-QSP scrolls vs MT Pentateuch', 'QSP scrolls vs MT Pentateuch',
                    unname(OTHER_COEF))
robustness <- imap_dfr(robustness_variants, function(file, variant) {
  m <- load_model(file)
  out <- effect_draws(m) |> mutate(variant = variant)
  rm(m); gc()
  out
}) |>
  filter(label %in% robust_effects) |>
  summarise_effects(label, variant) |>
  mutate(label = factor(label, levels = robust_effects),
         variant = factor(variant, levels = rev(names(robustness_variants)))) |>
  arrange(label, desc(variant))
robustness
write_csv(robustness, file.path(IMAGE_FOLDER, 'table_infc_lh_robustness.csv'))

p <- plot_or(robustness, variant,
             caption = paste0('Groups vs the MT Pentateuch (in M4 and M4p: its forms without a prefix).\n',
                              'Suffix and prefix vs none. Prior sensitivity: M4p with sd 1.5 and 4.\n',
                              OR_CAPTION)) +
  facet_grid(label ~ ., scales = 'free_y', space = 'free_y') +
  theme(strip.text.y = element_text(angle = 0, hjust = 0), plot.caption.position = 'plot')
p
save_book_figure(p, 'fig_infc_lh_robustness', width = 20, height = 18)

# ---- 4e. Random intercepts of the books (check) ----

p <- plot_random_intercepts(final_model, 'scr_book2', text_size = 5) + theme_book()
save_book_figure(p, 'check_infc_lh_random_books', height = 22)


# ==== 5. MODEL VERIFICATION ====

# Convergence, trace and density plots, posterior predictive checks, LOO (for
# completeness; unreliable with the nested structure) and Bayes R2. The
# in-sample classification it prints is optimistic.
verification <- verify_model(final_model, IMAGE_FOLDER, 'check_infc_lh')

# Observed vs predicted share of full spellings per group of books, per corpus
# with and without suffix, and for the most frequent lexemes (which have no
# fixed effect).
ppc_groups <- group_ppc(final_model, dat, 'law_phase3')
ppc_groups
save_book_figure(plot_ppc(ppc_groups), 'check_infc_lh_ppc_groups', height = 8)

dat$corpus_prs <- factor(paste(dat$corpus, if_else(dat$has_prs == 1, 'with suffix', 'without suffix')),
                         levels = paste(rep(levels(dat$corpus), each = 2),
                                        c('without suffix', 'with suffix')))
ppc_prs <- group_ppc(final_model, dat, 'corpus_prs')
ppc_prs
save_book_figure(plot_ppc(ppc_prs), 'check_infc_lh_ppc_suffix', height = 7)

main_lexemes <- c('<FH[', 'HJH[', 'R>H[', 'BNH[', '<LH[', 'CTH[')
dat$lex_main <- factor(if_else(dat$lex %in% main_lexemes, as.character(dat$lex), 'other lexemes'),
                       levels = c(main_lexemes, 'other lexemes'))
ppc_lex <- group_ppc(final_model, dat, 'lex_main')
ppc_lex
save_book_figure(plot_ppc(ppc_lex), 'check_infc_lh_ppc_lexemes', height = 7)
